
/**
 *		 入库汇总统计表模块
 *		 author:周作建   2011.06.01
 *		 checked by：
 **/


import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.materialAcct.stat.receiveStat.view.WinQueryCondition;
import cn.superion.materialAcct.util.MainToolBar;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;

import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

import flash.net.FileReference;
import flash.utils.ByteArray;

import mx.collections.ArrayCollection;
import mx.controls.DateField;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;

public static const DESTANATION:String="materialAcctReceiveStatImpl";
private var winY:int=0;
public var max:String='';
public var mit:String='';
[Bindable]
public var _dataProvider:ArrayCollection = new ArrayCollection();
public var _storageName:String = null; //用于接受弹出框传入的仓库名称
public var _billDate:String = null; //用于接受弹出框传入的制单日期
public var _accountDate:String = null; //用于接受弹出框传入的记账日期
public var _statFlag:String = null;//用于接受报表格式参数，以确定要打印的报表样式种类

/**
 * 初始化当前窗口
 * */
private function doInit():void
{
	parentDocument.title="入库汇总统计表";
	winY=this.parentApplication.screen.height - 345;
	initPanel();
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
	var excelTitle:String='入库汇总统计表'+_currentDate;
	file.save(mbytes,excelTitle+".xls");
}
/**
 * 输出按钮
 */
protected function toolBar_expClickHandler(event:Event):void
{
	if(_statFlag == "1"){
		makeExport(gdSaleGroup);
		
	}else if( _statFlag == "2"){
		
		makeExport(gdMasterialGroup1); //laryDataList = .dataProvider as ArrayCollection;
	}else if( _statFlag == "3"){
		
		makeExport(gdSaleMaterialGroup);//laryDataList = gdDeptMaterialGroup.dataProvider as ArrayCollection;
	}else{
		
		makeExport(gdSaleMaterialGroup);
	}
	
	
	
}

/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	var laryDataList:ArrayCollection=null;
	var dict:Dictionary=new Dictionary();
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="采购入库汇总表";
	dict["制单日期"]=_billDate;
	dict["供应单位"]= salerName.text;
	dict["记账日期"]=_accountDate;
	dict["制单"]=AppInfo.currentUserInfo.userName;
	dict["仓库"]=_storageName;
	var lstrReportFile:String="";
	if(_statFlag == '1'){ //供应商
		lstrReportFile = "report/materialAcct/stat/receiveList/receiveList.xml"
		laryDataList = gdSaleGroup.dataProvider as ArrayCollection;
		//
	}
	if(_statFlag == '2'){//物资
		lstrReportFile = "report/materialAcct/stat/receiveList/receiveList2.xml"
		laryDataList = gdMasterialGroup1.dataProvider as ArrayCollection;
		//
	}
	if(_statFlag == '3'){//供应商物资
		lstrReportFile = "report/materialAcct/stat/receiveList/receiveList3.xml"
		laryDataList = gdSaleMaterialGroup.dataProvider as ArrayCollection;
		//
	}
	for each(var item:Object in laryDataList){
		item.materialSpec = item.materialSpec == null ? "" : item.materialSpec;
		item.materialUnits = item.materialUnits == null ? "" : item.materialUnits;
		item.materialName = item.materialName == null ? "" : item.materialName;
		item.invoiceNo=item.invoiceNo==null?"":item.invoiceNo;
	}
	if(laryDataList.length<=0){return;}
	dict["起始入库号"] =mit;
	dict["结束入库号"] =max;
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
 * LabFunction，针对表格
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
	else if(column.headerText=="优惠金额"){ //批发 - 应付
		var subSaleTrade2:Number = (item.saleMoney - item.tradeMoney);
		item.subSaleTrade2 = subSaleTrade2;
		return subSaleTrade2.toFixed(2);
	}
	if(column.headerText=="供应单位"){ //item.tradeMoney 是 进价金额，= 发票
		//
		if(item.salerName){
			return item.salerName;
		}else{
			return item.salerCode;
		}
	}
	if(column.headerText=="进批差额"){ //item.tradeMoney 是 进价金额，= 发票
		//
		var subSaleTrade:Number = (item.saleMoney - item.tradeMoney);
		item.subSaleTrade = subSaleTrade;
		return subSaleTrade.toFixed(2); //根据实际报表中的 批发 - 发票
	}
	else if(column.headerText=="折让金额"){ //发票 - 应付
		//
		var subTradeFactTrade:Number = (item.tradeMoney - item.factTradeMoney);
		item.subTradeFactTrade = subTradeFactTrade ;
		return subTradeFactTrade.toFixed(2);
	}
	else if(column.headerText=="优惠总额"){ //批发 - 应付
		var subSaleFactTrade:Number = (item.saleMoney - item.factTradeMoney);
		item.subSaleFactTrade = subSaleFactTrade;
		return subSaleFactTrade.toFixed(2);
	}
	else if(column.headerText=="扣率"){//应付/批发
		if(item.factTradeMoney == null || item.factTradeMoney == 0 
		||item.saleMoney == null || item.saleMoney == 0){
			return "0.00";
		}else{
			var rateFactTradeSale:Number = (item.factTradeMoney / item.saleMoney);
			item.rateFactTradeSale = rateFactTradeSale ;
			return rateFactTradeSale.toFixed(2);
		}
	}
	else if(column.headerText=="缴现金"){//用戶也不知道什麽意思，這裡保留空
		return "";
	}else{
		return "0.00";
	}
}

