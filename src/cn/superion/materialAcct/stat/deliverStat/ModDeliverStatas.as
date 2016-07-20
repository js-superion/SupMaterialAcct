
/**
 *		 出库汇总统计表模块
 *		 author:周作建   2011.06.01
 *		 checked by：
 **/


import cn.superion.base.config.AppInfo;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.materialAcct.stat.deliverStat.view.WinQueryCondition;
import cn.superion.materialAcct.util.MainToolBar;
import cn.superion.materialAcct.util.MaterialDictShower;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.system.SysUnitInfor;

import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

import flash.net.FileReference;
import flash.utils.ByteArray;

import mx.collections.ArrayCollection;
import mx.controls.DateField;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

public static const DESTANATION:String="materialAcctDeliverStatImpl";
private var winY:int=0;
public var max:Date=new Date();
public var mit:Date=new Date();
[Bindable]
public var _dataProvider:ArrayCollection = new ArrayCollection();

public var _deptName:String = null; //用于接受弹出框传入的部门名称
public var _billDate:String = null; //用于接受弹出框传入的制单日期
public var _accountDate:String = null; //用于接受弹出框传入的记账日期
public var _statFlag:String = null;//用于接受报表格式参数，以确定要打印的报表样式种类
public var selectedUnitsName:String = null;//用于接受弹出框传入的 单位名称；

/**
 * 初始化当前窗口
 * */
private function doInit():void
{
	parentDocument.title="出库汇总统计表";
	winY=this.parentApplication.screen.height - 345;
	initPanel();
	var ro:RemoteObject = RemoteUtil.getRemoteObject("unitInforImpl",function(rev:Object):void{
		if(rev.data.length > 0 ){
			for each (var it:SysUnitInfor in rev.data){
				it.label = it.unitsSimpleName;
				it.data = it.unitsCode;
			}
			MaterialDictShower.SYS_UNITS = rev.data;
		}
	});
	ro.findByEndSign("1");
}

/**
 * 面板初始化
 */
private function initPanel():void
{
	initToolBar();
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[tbarMain.btPrint, tbarMain.btExp, tbarMain.imageList1, tbarMain.btQuery, tbarMain.imageList6, tbarMain.btExit]
	var laryEnables:Array=[tbarMain.btExit, tbarMain.btQuery]
	MainToolBar.showSpecialBtn(tbarMain, laryDisplays, laryEnables, true);
}


private function setToolBarWhenDatas():void
{
	var laryShowBts:Array=[tbarMain.btPrint, tbarMain.btExp, tbarMain.imageList1, tbarMain.btQuery, tbarMain.imageList6, tbarMain.btExit]
	var laryEnableBts:Array=[tbarMain.btPrint, tbarMain.btExp, tbarMain.btExit, tbarMain.btQuery]
	MainToolBar.showSpecialBtn(tbarMain, laryShowBts, laryEnableBts, true);
}


/**
 * 回车事件
 **/
private function toNextCtrl(event:KeyboardEvent, fctrlNext:Object):void
{
	FormUtils.toNextControl(event, fctrlNext);
}

/**
 * 打印按钮
 */
protected function toolBar_printClickHandler(event:Event):void
{
	//打印：1
	printReport("1");
	
}



private function addExcelHeader(dataList:Object,fsheet:Sheet):void{   
	var cols:Array=dataList.columns;	
	var i:int=0;
	for each(var col:* in cols){
		fsheet.setCell(0,i,col.headerText);
		i++;
	}
}

private function addExcelData(laryDataList:ArrayCollection,fsheet:Sheet,gridName:Object):void{
	var lintRow:int=1;
	var cols:Array=gridName.columns;
	for each(var litem:Object in laryDataList){
		var lintColumn:int = 0;
		var index:int =0;
		for each(var col:DataGridColumn in cols){
			fsheet.setCell(lintRow,0,lintRow ||'');
			fsheet.setCell(lintRow,lintColumn,litem[cols[index].dataField]|| '');
			index++;
			lintColumn ++;
		}
		lintRow ++;
	}
	
}


private function makeExport(dataGridName:Object):void{
	
	var laryDataList:ArrayCollection=new ArrayCollection();
	var cols:Array=[];
	var excelFile:ExcelFile = new ExcelFile();
	var sheet:Sheet = new Sheet();
	laryDataList = dataGridName.dataProvider as ArrayCollection;
	cols=dataGridName.columns;
	sheet.resize(dataGridName.dataProvider.length+1,cols.length);
	addExcelHeader(dataGridName,sheet);
	addExcelData(laryDataList,sheet,dataGridName);
	excelFile.sheets.addItem(sheet);
	var mbytes:ByteArray = excelFile.saveToByteArray();
	var  file:FileReference=new FileReference();
	var _currentDate:String=DateField.dateToString(new Date(),'YYYY-MM-DD');
	var excelTitle:String='出库汇总统计表'+_currentDate;
	file.save(mbytes,excelTitle+".xls");
}
/**
 * 输出按钮
 */
protected function toolBar_expClickHandler(event:Event):void
{
	if(_statFlag == "1"){
		makeExport(gdDeptGroup);
		
	}else if( _statFlag == "2"){
		
		makeExport(gdMasterialGroup1); //laryDataList = .dataProvider as ArrayCollection;
	}else if( _statFlag == "3"){
		
		makeExport(gdDeptMaterialGroup);//laryDataList = gdDeptMaterialGroup.dataProvider as ArrayCollection;
	}else{
		
		makeExport(gdMasterialGroup);
	}

	
	
}

/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	var laryDataList:ArrayCollection = null;
	var dict:Dictionary=new Dictionary();
	dict["出库单位"]=AppInfo.currentUserInfo.unitsName;
	dict["领用单位"]=selectedUnitsName?selectedUnitsName:"";;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="领用出库汇总表";
	dict["制单日期"]=_billDate;
	dict["记账日期"]=_accountDate;
	dict["制单"]=AppInfo.currentUserInfo.userName;
	dict["领用科室"]=_deptName ?_deptName:"";
	var lstrReportFile:String="";
	if(_statFlag == '1'){ //领用科室分组
		lstrReportFile = "report/materialAcct/stat/deliverList/deliverList.xml"
		laryDataList = gdDeptGroup.dataProvider as ArrayCollection;
	}
	if(_statFlag == '2'){//物资分组
		lstrReportFile = "report/materialAcct/stat/deliverList/deliverList2.xml"
		laryDataList = gdMasterialGroup1.dataProvider as ArrayCollection;
	}
	if(_statFlag == '3'){//科室、物资分组
		lstrReportFile = "report/materialAcct/stat/deliverList/deliverList3.xml"
		laryDataList = gdDeptMaterialGroup.dataProvider as ArrayCollection;
	}
	for each(var item:Object in laryDataList){
		item.materialSpec = item.materialSpec == null ? "" : item.materialSpec;
		item.materialUnits = item.materialUnits == null ? "" : item.materialUnits;
		item.materialName = item.materialName == null ? "" : item.materialName;
		if(item.salerName){
			item.salerName = item.salerName.substr(0,5);
		}
	}
	
	dict["结束入库号"] =DateUtil.dateToString(max,'YYYY-MM-DD');
	dict["起始入库号"] =DateUtil.dateToString(mit,'YYYY-MM-DD');
//	for each(var o:Object in laryDataList)
//	{
//		if(max<o.billDate)
//		{
//			dict["结束入库号"] =DateUtil.dateToString(o.billDate,'YYYY-MM-DD');
//		}
//		if(mit>o.billDate)
//		{
//			dict["起始入库号"] =DateUtil.dateToString(o.billDate,'YYYY-MM-DD');
//		}
//	}
	if (printSign == '1')
	{
		ReportPrinter.LoadAndPrint(lstrReportFile, laryDataList, dict);
		return;
	}
	
	ReportViewer.Instance.Show(lstrReportFile, laryDataList, dict);
}

/**
 * 查询事件
 */
protected function tbarMain_queryClickHandler(event:Event):void
{
	var win:WinQueryCondition=PopUpManager.createPopUp(this, WinQueryCondition, true) as WinQueryCondition;
	FormUtils.centerWin(win);
	win.iparentWin=this;
}


/**
 * 放弃按钮
 */
protected function tbarMain_cancelClickHandler(event:Event):void
{
}

/**
 * 退出按钮
 */
protected function tbarMain_exitClickHandler(event:Event):void
{
	PopUpManager.removePopUp(IFlexDisplayObject(this.parentDocument))
}
/**
 * LabFunction，针对表格扩充的字段进行处理
 * */
private function labFun(item:Object,column:DataGridColumn):String{
	if(column.headerText=="序号"){
		var index:int = _dataProvider.getItemIndex(item);
		item.serialNo = index + 1;
		return item.serialNo;
	}
	else if(column.headerText=="批零差额"){ //零售 - 批发
		var subRetailSale:Number = (item.retailMoney - item.saleMoney);
		item.subRetailSale = subRetailSale;
		return subRetailSale.toFixed(2);
	}
	else if(column.headerText=="批零差额（计价）"){ //零售 - 批发
		var subRetailSale1:Number = (item.retailMoney1 - item.saleMoney1);
		item.subRetailSale1 = subRetailSale1;
		return subRetailSale1.toFixed(2);
	}
	else if(column.headerText=="批零差额（不计价）"){ //零售 - 批发
		var subRetailSale0:Number = (item.retailMoney0 - item.saleMoney0);
		item.subRetailSale0 = subRetailSale0;
		return subRetailSale0.toFixed(2);
	}
	else if(column.headerText=="所属单位"){ //零售 - 批发
		//根据页面获得的单位列表，循环处理；
		var ss:String = "";
		for each (var unitInfo:Object in MaterialDictShower.SYS_UNITS){
			if(unitInfo.unitsCode == item.deptUnitsCode){
				ss = item.unitsSimpleName = unitInfo.unitsSimpleName;
				break;
			}
		}
		return ss;
	}else{
		return "0.00";
	}
}

