
/**
 *		 入库单报告列表模块
 *		 author:周作建   2011.06.01
 *       modify:吴小娟  2011.06.10
 *		 checked by：
 **/


import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.base.util.StringUtils;
import cn.superion.materialAcct.stat.receiveList.view.WinQueryCondition;
import cn.superion.materialAcct.util.DefaultPage;
import cn.superion.materialAcct.util.ReportParameter;
import cn.superion.materialAcct.util.ToolBar;
import cn.superion.report.hlib.UrlLoader;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;

import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

import flash.net.FileReference;
import flash.utils.ByteArray;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.core.IFlexDisplayObject;
import mx.events.ListEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.IndexChangeEvent;

public static const DESTINATION:String="materialAcctReceiveListImpl";
//菜单号
public static const MENU_NO:String="0202";
private var _flag:Boolean=true;
private var _rdsDetails:ArrayCollection=new ArrayCollection();
public var _isGive:String='';

/**
 * 初始化当前窗口
 * */
private function doInit():void
{
	parentDocument.title="入库报告单查询";
	initPanel();
	setPrintPageSize();
}

/**
 * 面板初始化
 */
private function initPanel():void
{
	initToolBar();
	dgMasterList.grid.horizontalScrollPolicy="on";	
	var passParam:ParameterObject=new ParameterObject();
	passParam.conditions={};
	dgMasterList.config(passParam, DESTINATION, 'findDeliverListByCondition', function(rev:Object):void
	{
		dgMasterList.grid.dataProvider=rev.data;
		rdBillNo.dataProvider=new ArrayCollection();
		rdBillNo.textInput.text='';
		dgDetailList.dataProvider=new ArrayCollection();
	}, null, false)
	dgMasterList.grid.addEventListener(ListEvent.CHANGE,gridDataChangeHandler);
}

private function gridDataChangeHandler(event:ListEvent):void{
	if(dgMasterList.grid.dataProvider.length > 0 ){
		toolBar.btExp.enabled = true;
		toolBar.btPrint.enabled = true;
	}
}
/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1, toolBar.btQuery, toolBar.imageList6, toolBar.btExit]
	var laryEnables:Array=[toolBar.btExit, toolBar.btQuery]
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 回车事件
 **/
private function toNextCtrl(event:KeyboardEvent, fctrlNext:Object):void
{
	FormUtils.toNextControl(event, fctrlNext);
}

/**
 * 当前角色权限认证
 */
public static function checkUserRole(role:String):Boolean
{
	//判断具有操作权限  -- 应用程序编号，菜单编号，权限编号
	// 01：增加                02：修改            03：删除
	// 04：保存                05：打印            06：审核
	// 07：弃审                08：输出            09：输入
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO, role))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return false;
	}
	return true;
}

/**
 * 点击左边列表选中的内容，查询右边入库号和列表明细
 * */
protected function dgMasterList_itemClickHandler(event:Event):void
{
	if(!dgMasterList.grid.selectedItem){
		return;
	}
	var lstrAcctBillNo:String=dgMasterList.grid.selectedItem.autoId;
	
	
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
	{
		if (rev.data && rev.data.length > 0)
		{
			toolBar.btPrint.enabled=true;
			toolBar.btExp.enabled=true;
			//明细列表
			dgDetailList.dataProvider=rev.data;
			//入库号
			_rdsDetails=rev.data;
			var laryRdBillNo:ArrayCollection=new ArrayCollection();
			for each(var item:Object in rev.data){
				var lnewArray:Object=new Object();
				_flag=true;
				//判断入库号不重复
				for each(var it:Object in laryRdBillNo){
					if(item.rdBillNo!=null &&it.rdBillNo == item.rdBillNo){
						_flag=false;
						break;
					}
				}
				if(_flag){ 
					lnewArray.rdBillNo=item.rdBillNo;
					laryRdBillNo.addItem(lnewArray);
				}
			}
			laryRdBillNo.removeItemAt(laryRdBillNo.length-1);
			rdBillNo.dataProvider=laryRdBillNo;
			return;
		}else{
			dgDetailList.dataProvider = new ArrayCollection();
		}
	});
	ro.findByAcctBillNo(lstrAcctBillNo,_isGive);
}

/**
 * 根据选中的入库号查询右边列表明细
 * */
protected function rdBillNo_changeHandler(event:IndexChangeEvent):void
{
	if(!rdBillNo.selectedItem){
		dgMasterList_itemClickHandler(event);
		return;
	}
	var laryDetails:ArrayCollection=_rdsDetails;
	var lnewDetails:ArrayCollection=new ArrayCollection();
	for each(var item:Object in laryDetails){
		if(rdBillNo.selectedItem.rdBillNo == item.rdBillNo && item.isGive == _isGive){
			lnewDetails.addItem(item);
		}
	}
	dgDetailList.dataProvider=lnewDetails;
}


private function labFun(item:Object, column:DataGridColumn):*{
	if(column.headerText == '记账人'){
		item.accounterName='';
		var tarItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', item.accounter);
		if(tarItem){
			item.accounterName=tarItem.personIdName;
		}
		return item.accounterName;
	}
}

/**
 * 打印按钮
 */
protected function toolBar_printClickHandler(event:Event):void
{
	//打印权限
	if (!checkUserRole('05'))
	{
		return;
	}
	//打印：1
	printReport("1");
	
}

protected function toolBar_expClickHandler(event:Event):void
{
	//输出权限
	if (!checkUserRole('08'))
	{
		return;
	}
	//输出：0
	makeExport(dgDetailList);
	
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
	var excelTitle:String='入库报告单'+_currentDate;
	file.save(mbytes,excelTitle+".xls");
}
private function preparePrintData(faryData:ArrayCollection):void
{
	var rdBillNo:String=""
	var pageNo:int=0;
	for (var i:int=0; i < faryData.length; i++)
	{
		var item:Object=faryData.getItemAt(i);
		if(item.rdBillNo!=rdBillNo){
			rdBillNo=item.rdBillNo
			pageNo++;
		}
		item.factoryName=!item.factoryName ? '' : item.factoryName
		item.pageNo=pageNo;
		item.factoryName = item.factoryName.substr(0,6);
//		item.wholeSalePerPage = item.amount * item.wholeSalePrice;
//		item.tradePerPage = item.amount * item.tradePrice; //当前页进价
//		item.wholeSalePerPage = item.amount * item.wholeSalePrice;
		item.packageUnits = item.packageUnits == null ? item.materialUnits : item.packageUnits;
		item.nameSpec = item.materialName + "  "+(item.packageSpec == null ? "" : item.packageSpec);
			
	}
}
private function createPrintFirstBottomLine():String
{
	var rawData:ArrayCollection = dgDetailList.getRawDataProvider() as ArrayCollection;
	var lastItem:Object=rawData.getItemAt(rawData.length - 1);
	var lstrLine:String="    批发总额：{0}      进价总额：{1}            零售总额：{2}";
	lstrLine=StringUtils.format(lstrLine, 
		(lastItem.wholeSaleMoney == null ? 0 :lastItem.wholeSaleMoney ).toFixed(2), 
		(lastItem.tradeMoney== null ? 0 :lastItem.tradeMoney).toFixed(2), 
		(lastItem.retailMoney== null ? 0 :lastItem.retailMoney).toFixed(2))
	return lstrLine
}

private function createPrintSecondBottomLine():String
{
	var rawData:ArrayCollection = dgDetailList.getRawDataProvider() as ArrayCollection;
	var lastItem:Object=rawData.getItemAt(rawData.length - 1);
	var accounter:Object = ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',dgMasterList.grid.selectedItem.accounter) ;
	var lstrLine:String="    主任：{0}           采购：{1}         保管：{2}         会计：{3}         批零差：{4}";
	lstrLine=StringUtils.format(lstrLine, 
		"",
		"",
		"",
		accounter?accounter.personIdName:"", 
		(lastItem.retailMoney - lastItem.wholeSaleMoney).toFixed(2))
	return lstrLine;
}
/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	setPrintPageSize();
	var _dataList:ArrayCollection=dgDetailList.dataProvider as ArrayCollection;
	preparePrintData(_dataList);
	var giveFlag:Boolean=false;
	for each (var item:Object in _dataList){
		if(item.factoryName){
			item.factoryName = item.factoryName.substr(0,5);
		}
		item.nameSpec = item.materialName+"  " + (item.materialSpec == null ? "" : item.materialSpec);
		item.invoiceNo = item.invoiceNo == null?"":item.invoiceNo;
		if(item.isGive=='1'){
			giveFlag=true;
		}
	}
	var dict:Dictionary=new Dictionary();
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="入库报告单";
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	var accounter:Object = ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',dgMasterList.grid.selectedItem.accounter) ;
	dict["会计"]=accounter?accounter.personIdName:"";
	dict["进货单位"]=dgMasterList.grid.selectedItem.salerName ? dgMasterList.grid.selectedItem.salerName.substr(0,17) : "";
	dict["日期范围"]="从 " + DateUtil.dateToString(dgMasterList.grid.selectedItem.billDate1,'YYYY-MM-DD') + " 到 " + DateUtil.dateToString(dgMasterList.grid.selectedItem.billDate2,'YYYY-MM-DD') + "";
	dict["仓库"]=dgMasterList.grid.selectedItem.storageName == null ? "":dgMasterList.grid.selectedItem.storageName;
	if(giveFlag=='1'){
		dict["仓库"]=dict["仓库"]+'(zs)'
	}
	dict["表尾第一行"]=createPrintFirstBottomLine()
	dict["表尾第二行"]=createPrintSecondBottomLine()
	dict["起始号"]= _dataList.length > 0 ? _dataList[0].rdBillNo:"";
	dict["结束号"]= _dataList.length > 0 ? _dataList[_dataList.length - 1 ].rdBillNo:"";
	var lstrReportFile:String="report/materialAcct/daily/receiveReport/receive2.xml";//receive2字体为8号；
	loadReportXml(lstrReportFile, _dataList, dict,printSign)
}

/**
 * 加载报表xml修改高度并打印
 * */
private function loadReportXml(reportUrl:String,faryDetails:ArrayCollection, fdict:Dictionary,fprintSign:String):void{
	var loader:UrlLoader=new UrlLoader();
	loader.addEventListener(Event.COMPLETE, function(event:Event):void{
		var xml:XML=XML(event.currentTarget.Data)
		var ss:String = ReportParameter.reportPrintHeight_in;
//		if(ReportParameter.reportPrintHeight_in&&ReportParameter.reportPrintHeight_in!='0'){
//			var lreportHeight:String=parseFloat(ReportParameter.reportPrintHeight_in)/10+''
//			xml.PageHeight=lreportHeight	
//		}
		if (fprintSign == "1")
		{
			ReportPrinter.Print(xml, faryDetails, fdict);
		}
		else
		{
			ReportViewer.Instance.Show(xml, faryDetails, fdict);
		}
	});
	loader.Load(reportUrl);
}
/**
 * 查询事件
 */
protected function toolBar_queryClickHandler(event:Event):void
{
	var win:WinQueryCondition=PopUpManager.createPopUp(this, WinQueryCondition, true) as WinQueryCondition;
	FormUtils.centerWin(win);
	win.iparentWin=this;
}

/**
 * 退出按钮
 */
protected function toolBar_exitClickHandler(event:Event):void
{
	PopUpManager.removePopUp(IFlexDisplayObject(this.parentDocument));
	DefaultPage.gotoDefaultPage();
}
/**
 * 设置默认打印机的打印页面
 * */
private function setPrintPageSize():void{
	var lnumWidth:Number=210*1000
	var lnumHeight:Number=parseFloat(ReportParameter.reportPrintHeight_in)
	lnumHeight=isNaN(lnumHeight)?288*1000:lnumHeight*1000 
	ExternalInterface.call("setPrintPageSize",lnumWidth,lnumHeight)
}

