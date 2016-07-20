
/**
 *		 出库单报告列表模块
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
import cn.superion.materialAcct.stat.deliverList.view.WinQueryCondition;
import cn.superion.materialAcct.util.MainToolBar;
import cn.superion.materialAcct.util.MaterialDictShower;
import cn.superion.materialAcct.util.ReportParameter;
import cn.superion.report.hlib.UrlLoader;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.system.SysUnitInfor;

import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

import flash.net.FileReference;
import flash.utils.Dictionary;

import mx.collections.ArrayCollection;
import mx.collections.IViewCursor;
import mx.collections.Sort;
import mx.collections.SortField;
import mx.controls.DateField;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.core.IFlexDisplayObject;
import mx.events.IndexChangedEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.IndexChangeEvent;

public static const DESTANATION:String="materialAcctDeliverListImpl";
private var _rdsDetails:ArrayCollection=new ArrayCollection();
private var winY:int=0;
public var deptName:String = null
public var storageName:String = null
public var beginBillDate:Date = null
public var endBillDate:Date = null
private var PAGE_SIZE:int = 10;
private var _flag:Boolean=true;
private var laryRdBillNo:ArrayCollection= new ArrayCollection();
/**
 * 初始化当前窗口
 * */
private function doInit():void
{
	parentDocument.title="出库报告单查询";
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
	dgMasterList.config(passParam, DESTANATION, 'findDeliverListByCondition', function(rev:Object):void
	{
		if(rev.data.length<=0)
		{
			tbarMain.btPrint.enabled=false;
			tbarMain.btExp.enabled=false;
			gdItems.dataProvider = new ArrayCollection();
			return;
		}
		tbarMain.btPrint.enabled=true;
		tbarMain.btExp.enabled=true;
		dgMasterList.grid.dataProvider=rev.data;
		billNo.dataProvider=new ArrayCollection();
		billNo.textInput.text='';
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
 * 点击左边列表选中的内容，查询右边入库号和列表明细
 **/
protected function dgMasterList_clickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	if(!dgMasterList.grid.selectedItem){
		return;
	}
	var lstrAcctBillNo:String=dgMasterList.grid.selectedItem.autoId;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		if (rev.data && rev.data.length > 0)
		{
			tbarMain.btPrint.enabled=true;
			tbarMain.btExp.enabled=true;
			//明细列表
			gdItems.dataProvider=rev.data;
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
			billNo.dataProvider=laryRdBillNo;
			return;
		}else{
			gdItems.dataProvider = new ArrayCollection();
		}
	});
	ro.findByAcctBillNo(lstrAcctBillNo);
}
/**
 * 根据选中的入库号查询右边列表明细
 * */
protected function billNo_changeHandler(event:IndexChangeEvent):void
{
	if(!billNo.selectedItem){
		dgMasterList_clickHandler(event);
		return;
	}
	var laryDetails:ArrayCollection=_rdsDetails;
	var lnewDetails:ArrayCollection=new ArrayCollection();
	for each(var item:Object in laryDetails){
		if(billNo.selectedItem.rdBillNo == item.rdBillNo){
			lnewDetails.addItem(item);
		}
	}
	gdItems.dataProvider=lnewDetails;
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
 * 退出按钮
 */
protected function tbarMain_exitClickHandler(event:Event):void
{
	PopUpManager.removePopUp(IFlexDisplayObject(this.parentDocument))
}

/**
 * labelFunction事件
 */ 
private function labelFun(item:Object, column:DataGridColumn):*
{
	if (column.headerText == "生产厂家")
	{
		var factoryCodeItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict, 'provider', item.factoryCode);
		if (!factoryCodeItem)
		{
			return '';
		}
		else
		{
			item.factoryName=factoryCodeItem.providerName;
			return factoryCodeItem.providerName;
		}
	}
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
	var excelTitle:String='出库报告单'+_currentDate;
	file.save(mbytes,excelTitle+".xls");
}
private function createPrintSecondBottomLine():String
{
	var rawData:ArrayCollection = gdItems.getRawDataProvider() as ArrayCollection;
	var lastItem:Object=rawData.getItemAt(rawData.length - 1);
	var accounter:Object = ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',dgMasterList.grid.selectedItem.accounter) ;
	var lstrLine:String="    会计：{0}          保管：{1}          经领人：{2}          制单：{3}";
	lstrLine=StringUtils.format(lstrLine, 
		accounter?accounter.personIdName:"",
		"",
		"",
		accounter?accounter.personIdName:"")
	return lstrLine;
}
private function createPrintFirstBottomLine():String
{
	var rawData:ArrayCollection = gdItems.getRawDataProvider() as ArrayCollection;
	var lastItem:Object=rawData.getItemAt(rawData.length - 1);
	var lstrLine:String="    批发总额：{0}            零售总额：{1}           批零差额：{2} ";
	lstrLine=StringUtils.format(lstrLine,  
		( lastItem.wholeSaleMoney).toFixed(2), 
		( lastItem.retailMoney ).toFixed(2),
		 (lastItem.retailMoney - lastItem.wholeSaleMoney).toFixed(2)); 
		
	return lstrLine
}
private function preparePrintData(faryData:ArrayCollection):void
{
	var rdBillNo:String=""
	var pageNo:int=0;
	//
	for (var i:int=0; i < faryData.length; i++)
	{
		var item:Object=faryData.getItemAt(i);
		if(item.rdBillNo!=rdBillNo){
			rdBillNo=item.rdBillNo
			pageNo++;
			laryRdBillNo.addItem(rdBillNo);
		}
		item.currentPageNo=int(i / PAGE_SIZE) + 1
		item.factoryName=!item.factoryName ? '' : item.factoryName
		item.pageNums=pageNo;
		item.nameSpec = item.materialName+"  "+ (item.materialSpec == null ? "" : item.materialSpec);
	}
}
/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	var dict:Dictionary=new Dictionary();
	var deptUnitsName:String = "";
	for each (var it:Object in MaterialDictShower.SYS_UNITS){
		if(it.unitsCode == dgMasterList.grid.selectedItem.deptUnitsCode){
			deptUnitsName = it.unitsSimpleName;
		}
	}
	dgMasterList.grid.selectedItem.retailSum 
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="出库报告单";
	dict["制表人"]=AppInfo.currentUserInfo.userName;
	dict["仓库"]=dgMasterList.grid.selectedItem.storageName == null ? "":dgMasterList.grid.selectedItem.storageName;
	dict["请领单位"]=deptUnitsName; //领用科室所在的单位
	dict["请领部门"]=dgMasterList.grid.selectedItem.deptName == null ? "" : dgMasterList.grid.selectedItem.deptName;
//	
	dict["日期范围"]="从" + DateUtil.dateToString(dgMasterList.grid.selectedItem.billDate1,'YYYY-MM-DD') + "到" + DateUtil.dateToString(dgMasterList.grid.selectedItem.billDate2,'YYYY-MM-DD') + "";
	dict["表尾第一行"]=createPrintFirstBottomLine()
	dict["表尾第二行"]=createPrintSecondBottomLine()
	
	var dataList:ArrayCollection=gdItems.dataProvider as ArrayCollection;
	preparePrintData(dataList);
	
	dict["起始号"]= dataList.length > 0 ? dataList[0].rdBillNo:"";
	dict["结束号"]= dataList.length > 0 ? dataList[dataList.length - 1 ].rdBillNo:"";
	laryRdBillNo.removeAll();
	for each (var item:Object in dataList){
		if(item.factoryName){
			item.factoryName = item.factoryName.substr(0,5);
		}
		
		item.detailRemark = item.detailRemark == null ? "" : item.detailRemark;
	}
	loadReportXml("report/materialAcct/daily/deliverReport/deliverReport.xml", dataList, dict,printSign)
}

/**
 * 加载报表xml修改高度并打印
 * */
private function loadReportXml(reportUrl:String,faryDetails:ArrayCollection, fdict:Dictionary,fprintSign:String):void{
	var loader:UrlLoader=new UrlLoader();
	loader.addEventListener(Event.COMPLETE, function(event:Event):void{
		var xml:XML=XML(event.currentTarget.Data)
		if(ReportParameter.reportPrintHeight_out&&ReportParameter.reportPrintHeight_out!='0'){
			var lreportHeight:String=parseFloat(ReportParameter.reportPrintHeight_out)/10+''
			xml.PageHeight=lreportHeight	
		}
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
 * 设置默认打印机的打印页面
 * */
private function setPrintPageSize():void{
	var lnumWidth:Number=210*1000
	var lnumHeight:Number=parseFloat(ReportParameter.reportPrintHeight_in)
	lnumHeight=isNaN(lnumHeight)?288*1000:lnumHeight*1000 
	ExternalInterface.call("setPrintPageSize",lnumWidth,lnumHeight)
}


/**
 * 恢复默认打印机的打印页面
 * */
private function setPrintPageToDefault():void{
	ExternalInterface.call("setPrintPageToDefault")
}