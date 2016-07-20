
/**
 *		 当前库存量查询模块
 *		 author:周作建   2011.06.01
 *		 checked by：
 **/


import cn.superion.base.config.AppInfo;
import cn.superion.base.util.FormUtils;
import cn.superion.materialAcct.stat.currentStock.view.WinQueryCondition;
import cn.superion.materialAcct.util.MainToolBar;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;

import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

import flash.utils.ByteArray;
import flash.utils.Dictionary;

import mx.collections.ArrayCollection;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;

public static const DESTANATION:String="materialAcctCurrentStockStatImpl";
private var _winY:int=0;

public var _storageName:String = null; //用于接受弹出框传入的仓库名称
public var _billDate:String = null; //用于接受弹出框传入的制单日期
public var _accountDate:String = null; //用于接受弹出框传入的记账日期
public var _statFlag:String = null;//用于接受报表格式参数，以确定要打印的报表样式种类
/**
 * 初始化当前窗口
 * */
private function doInit():void
{
	parentDocument.title="当前库存量查询";
	_winY=this.parentApplication.screen.height - 345;
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

/**
 * 输出按钮
 */
protected function toolBar_expClickHandler(event:Event):void
{
	//输出：0
	makeExport(gdItems);
	
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
	var excelTitle:String='当前现存量统计表'+_currentDate;
	file.save(mbytes,excelTitle+".xls");
}
/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	var laryDataList:ArrayCollection=null;
	laryDataList = gdItems.dataProvider as ArrayCollection;
	var dict:Dictionary=new Dictionary();
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="当前库存量汇总";
	dict["制单日期"]=_billDate;
	dict["记账日期"]=_accountDate;
	dict["仓库"]=_storageName;
	var lstrReportFile:String="report/materialAcct/stat/currentStock/currentStock.xml";
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
	win.parentWin = this;
	FormUtils.centerWin(win);
}

/**
 * 退出按钮
 */
protected function tbarMain_exitClickHandler(event:Event):void
{
	PopUpManager.removePopUp(IFlexDisplayObject(this.parentDocument))
}


