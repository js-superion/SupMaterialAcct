
/**
 *		 出库汇总统计表模块
 *		 author:周作建   2011.06.01
 *		 checked by：
 **/


import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.materialAcct.stat.deliverStatByAccout.view.WinQueryCondition;
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
import mx.controls.advancedDataGridClasses.AdvancedDataGridColumn;
import mx.controls.advancedDataGridClasses.AdvancedDataGridColumnGroup;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;
import mx.printing.PrintAdvancedDataGrid;
import mx.rpc.remoting.RemoteObject;

public static const DESTANATION:String="materialAcctDeliverStatImpl";
private var winY:int=0;
public var max:Date=new Date();
public var mit:Date=new Date();
[Bindable]
public var _dataProvider:ArrayCollection = new ArrayCollection();

public var _deptName:String = null; //用于接受弹出框传入的部门名称
public var _billDate:String = null; //用于接受弹出框传入的制单日期
public var _billDate2:Date = null; //用于接受弹出框传入的制单日期
public var _billDate1:Date = null; //用于接受弹出框传入的制单日期
public var _accountDate:String = null; //用于接受弹出框传入的记账日期
public var _statFlag:String = null;//用于接受报表格式参数，以确定要打印的报表样式种类
public var selectedUnitsName:String = null;//用于接受弹出框传入的 单位名称；

/**
 * 初始化当前窗口
 * */
private function doInit():void
{
	parentDocument.title="会计科目汇总统计表";
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
	var cols:Array=gridAntibacterialList1.groupedColumns;	
	var i:int=0;
	for each(var col:* in cols){
		if(col is AdvancedDataGridColumnGroup && col.children)
		{
			fsheet.setCell(0,i,col.headerText);
			for (var m:int=0;m<col.children.length;m++)
			{
				fsheet.setCell(1,i,col.children[m].headerText);
				i++;
			}
		}
		else
		{
			fsheet.setCell(1,i,col.headerText);
			i++;
		}
		
	}
}

private function addExcelData(laryDataList:ArrayCollection,fsheet:Sheet,gridName:Object):void{
	var lintRow:int=2;
	var cols:Array=gridName.columns;
	for each(var litem:Object in laryDataList){
		var lintColumn:int = 0;
		var index:int =0;
		for each(var col:AdvancedDataGridColumn in cols){
//			fsheet.setCell(lintRow,0,lintRow ||'');
			if(cols[index].dataField=='deptUnitsCode')
			{
				var ss:String = "";
				for each (var unitInfo:Object in MaterialDictShower.SYS_UNITS){
					if(unitInfo.unitsCode == litem["deptUnitsCode"]){
						ss = unitInfo.unitsSimpleName;
						break;
					}
				}
				fsheet.setCell(lintRow,lintColumn,ss || '');
			}
			else if(cols[index].dataField=='deptCode')
			{
				var deptName:String='';
				var dept:Object = ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict,'dept',litem.deptCode) ;
				if(dept==null)
				{ 
					deptName = "合计";
				}
				else
				{
					deptName=dept.deptName;
				}
				fsheet.setCell(lintRow,lintColumn,deptName || '');
			}
			else
			{
				fsheet.setCell(lintRow,lintColumn,litem[cols[index].dataField]|| '');
			}
			
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
	sheet.resize(dataGridName.dataProvider.length+2,cols.length);
	addExcelHeader(dataGridName,sheet);
	addExcelData(laryDataList,sheet,dataGridName);
	excelFile.sheets.addItem(sheet);
	var mbytes:ByteArray = excelFile.saveToByteArray();
	var  file:FileReference=new FileReference();
	var _currentDate:String=DateField.dateToString(new Date(),'YYYY-MM-DD');
	var excelTitle:String='会计科目汇总统计表'+_currentDate;
	file.save(mbytes,excelTitle+".xls");
}
/**
 * 输出按钮
 */
protected function toolBar_expClickHandler(event:Event):void
{
		
//	printReport("0");
	makeExport(gridAntibacterialList1);
	
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
	dict["主标题"]="出库汇总表";
	dict["制单日期"]=dict["日期"];
	dict["记账日期"]=_accountDate;
	dict["开始出库日期"]=DateUtil.dateToString(_billDate1,'YYYY-MM-DD');
	dict["结束出库日期"]=DateUtil.dateToString(_billDate2,'YYYY-MM-DD');
	dict["制单"]=AppInfo.currentUserInfo.userName;
	dict["领用科室"]=_deptName ?_deptName:"";
	var lstrReportFile:String="";
		lstrReportFile = "report/materialAcct/stat/deliverList/deliverListByAccount.xml"
		laryDataList = gridAntibacterialList1.dataProvider as ArrayCollection;
	for each(var item:Object in laryDataList){
		item.materialSpec = item.materialSpec == null ? "" : item.materialSpec;
		item.materialUnits = item.materialUnits == null ? "" : item.materialUnits;
		item.materialName = item.materialName == null ? "" : item.materialName;
		
		if(item.salerName){
			item.salerName = item.salerName.substr(0,5);
		}
	}
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
 * 退出按钮
 */
protected function tbarMain_exitClickHandler(event:Event):void
{
	PopUpManager.removePopUp(IFlexDisplayObject(this.parentDocument))
}

/**
 * LabFunction，针对表格扩充的字段进行处理
 * */
private function labFun(item:Object,column:AdvancedDataGridColumn):String{
	if(column.headerText=="序号"){
		var index:int = _dataProvider.getItemIndex(item);
		item.serialNo = index + 1;
		return item.serialNo;
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
	}else if(column.headerText=="部门"){ //零售 - 批发
		//根据页面获得的单位列表，循环处理；
		var dept:Object = ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict,'dept',item.deptCode) ;
		if(dept==null)
		{ 
			item.deptName = "合计";
			return "合计";
		}
		return dept.deptName;
	}else{
		return "0.00";
	}
}

