
/**
 *		 调价记录列表模块
 *		 author:周作建   2011.06.01
 *		 checked by：
 **/


import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.base.util.StringUtils;
import cn.superion.materialAcct.stat.priceList.view.WinQueryCondition;
import cn.superion.materialAcct.util.MainToolBar;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;

import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

import flash.net.FileReference;

import mx.collections.ArrayCollection;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

public static const DESTANATION:String="materialAcctChangePriceListImpl";
private var winY:int=0;

/**
 * 初始化当前窗口
 * */
private function doInit():void
{
	parentDocument.title="调价记录单查询";
	winY=this.parentApplication.screen.height - 345;
	initPanel();
}

/**
 * 面板初始化
 */
private function initPanel():void
{
	initToolBar();
	var passParam:ParameterObject=new ParameterObject();
	passParam.conditions={};
	dgMasterList.config(passParam, DESTANATION, 'findChangeListByCondition', function(rev:Object):void
	{
		if(rev.data.length<=0)
		{
			tbarMain.btPrint.enabled=false;
			tbarMain.btExp.enabled=false;
			dgMasterList.grid.dataProvider=null;
			gdItems.dataProvider=null;
			return;
		}
		dgMasterList.grid.dataProvider=rev.data;
		gdItems.dataProvider=new ArrayCollection();
	}, null, false)
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
//打印
protected function printClickHandler(event:Event):void
{
	printReport("1");
	
}

protected function expClickHandler(event:Event):void
{
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
	var excelTitle:String='调价记录单'+_currentDate;
	file.save(mbytes,excelTitle+".xls");
}
/**
 * 计算当前页
 * */
private function preparePrintData(faryData:ArrayCollection):void
{
	var storageCode:String=""
	var pageNo:int=0;
	for (var i:int=0; i < faryData.length; i++)
	{
		var item:Object=faryData.getItemAt(i);
		item.factoryName=!item.factoryName ? '' : item.factoryName
		item.pageNums=pageNo;
		item.factoryName = item.factoryName.substr(0,6);
		item.materialSpec = item.materialSpec == null ? "" : item.materialSpec;
		item.nameSpec = item.materialName + "    "+(item.materialSpec == null ? "" : item.materialSpec);
	}
}

/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	var dataList:ArrayCollection=gdItems.dataProvider as ArrayCollection;
	var rawData:ArrayCollection = gdItems.getRawDataProvider() as ArrayCollection;
	var lastItem:Object=rawData.getItemAt(rawData.length - 1);
	preparePrintData(dataList);
	var dict:Dictionary=new Dictionary();
	dict["主标题"]="调价记录单";
	dict["调价单号"]=dgMasterList.grid.selectedItem.billNo;
	dict["调价日期"]=dgMasterList.grid.selectedItem.billDate;
	dict["审核"]=shiftTo(dgMasterList.grid.selectedItem.verifier)
	dict["制单"]=shiftTo(dgMasterList.grid.selectedItem.maker);
//	dict["表尾第一行"]=createPrintSecondBottomLine(lastItem);
	if (printSign == "1")
	{
		ReportPrinter.LoadAndPrint("report/materialAcct/daily/price/ChangePrice.xml", dataList, dict);
	}
	else
	{
		ReportViewer.Instance.Show("report/materialAcct/daily/price/ChangePrice.xml", dataList, dict);
	}
}
///**
// * 生成表格尾第一行
// * */
//private function createPrintSecondBottomLine(fLastItem:Object):String
//{
//	var lstrLine:String="审核：{0}                                                                                                  制单：{1}";
//	var makerv:String=shiftTo(dgMasterList.grid.selectedItem.maker);
//	var verifierv:String=shiftTo(dgMasterList.grid.selectedItem.verifier)
//	lstrLine=StringUtils.format(lstrLine, 
//		verifierv,
//		makerv)
//	return lstrLine;
//}
/**
 * 查询事件
 */
protected function tbarMain_queryClickHandler(event:Event):void
{
	var win:WinQueryCondition=PopUpManager.createPopUp(this, WinQueryCondition, true) as WinQueryCondition;
	win.iparentWin=this;
	FormUtils.centerWin(win);
}

/**
 * PageGrid控件ItemClick事件
 */ 
protected function dgMasterList_itemClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	// TODO Auto-generated method stub
	if(!dgMasterList.grid.selectedItem){
		return;
	}
	var lstrAcctBillNo:String=dgMasterList.grid.selectedItem.autoId;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		if (rev.data && rev.data.length > 0)
		{
			gdItems.dataProvider=rev.data;
			tbarMain.btPrint.enabled=true;
			tbarMain.btExp.enabled=true;
			return;
		}
		tbarMain.btPrint.enabled=false;
		tbarMain.btExp.enabled=false;
		gdItems.dataProvider=null;
	});
	ro.findByChangeBillNo(lstrAcctBillNo);
	
}
/**
 * 
 */
private function labelFun(item:Object, salerCode:DataGridColumn):*
{
	if (salerCode.headerText == "售价盘盈金额")
	{
		item.RetailPrices=(Number(item.newRetailPrice)-Number(item.oldRetailPrice))*Number(item.amount);
		return item.RetailPrices;
	}
	if (salerCode.headerText == "批发价盘盈金额")
	{
		item.SalePrices=(Number(item.oldWholeSalePrice)-Number(item.newWholeSalePrice))*Number(item.amount);
		return item.SalePrices;
	}
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

// 制单人
protected function shiftTo(name:String):String
{
	var makerItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', name);
	var maker:String=makerItem == null ? "" : makerItem.personIdName;
	return maker;
}
