
/**
 *		 采购入库单模块
 *		 author:周作建   2011.06.01
 *		 checked by：
 **/

import cn.superion.base.components.controls.DateFieldText;
import cn.superion.base.components.controls.SuperDataGrid;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialAcct.daily.receive.view.DateFieldTextEditor;
import cn.superion.materialAcct.daily.receive.view.NumbericEditor;
import cn.superion.materialAcct.util.DefaultPage;
import cn.superion.materialAcct.util.MaterialDictShower;
import cn.superion.materialAcct.util.ReportParameter;
import cn.superion.materialAcct.util.ToolBar;
import cn.superion.report.hlib.UrlLoader;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialRdsDetail;
import cn.superion.vo.system.SysUnitInfor;

import com.adobe.utils.ArrayUtil;
import com.adobe.utils.StringUtil;
import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

import flash.events.Event;
import flash.external.ExternalInterface;
import flash.net.FileReference;

import mx.collections.ArrayCollection;
import mx.collections.ListCollectionView;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.controls.dataGridClasses.DataGridColumn;
import mx.core.IFlexDisplayObject;
import mx.core.INavigatorContent;
import mx.events.CloseEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.styles.CSSStyleDeclaration;
import mx.styles.StyleManager;
import mx.utils.ObjectUtil;
import mx.controls.DataGrid;

import spark.components.supportClasses.ItemRenderer;
import spark.events.TextOperationEvent;

registerClassAlias("cn.superion.material.entity.MaterialRdsDetail", cn.superion.vo.material.MaterialRdsDetail);

public static const DESTINATION:String="materialAcctReceiveImpl";
//菜单号
public static const MENU_NO:String="0101";
//条件对象
private static var _condition:Object={};
private var PAGE_SIZE:int=10;
private var isSave:Boolean = true;
private var _winY:int=0;

//发票号为空时，是否允许勾选，东方医院=true，泰州=false;
public var _isSelected:Boolean=false;

private var laryNew:ArrayCollection=new ArrayCollection();
private var laryArray:Array=[];
/**
 * 初始化当前窗口
 * */
private function doInit():void
{
	parentDocument.title="采购入库单";
	_winY=this.parentApplication.screen.height - 345;
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
	
	if(MaterialDictShower.isAllUnitsDict)
	{
		MaterialDictShower.getAdvanceDictList();
	}

	_isSelected=ExternalInterface.call("getIsSelected");
}

protected function btselect_clickHandler(event:MouseEvent):void
{
	if(_isSelected==false)
	{
		for each (var item:Object in gdItems.dataProvider){
			if (item.invoiceNo || item.isGive == '1'){
					item.isSelected=true;
			}
		}
	}
	else
	{
		for each (var item:Object in gdItems.dataProvider){
					item.isSelected=true;
		}
	}
	ListCollectionView(gdItems.dataProvider).itemUpdated(item, "isSelected");
	DataGrid(gdItems).invalidateList();
}

protected function btNotselect_clickHandler(event:MouseEvent):void
{
	if(_isSelected==false)
	{
		for each (var item:Object in gdItems.dataProvider){
			if (item.invoiceNo || item.isGive == '1'){
				item.isSelected=false;
			}
		}
	}
	else
	{
		for each (var item:Object in gdItems.dataProvider){
			item.isSelected=false;
		}
	}
	ListCollectionView(gdItems.dataProvider).itemUpdated(item, "isSelected");
	DataGrid(gdItems).invalidateList();
}

/**
 * 面板初始化
 */
private function initPanel():void
{
	initToolBar();
	//授权仓库赋值
	if (AppInfo.currentUserInfo.storageList != null && AppInfo.currentUserInfo.storageList.length > 0)
	{
		storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
		storageCode.selectedIndex=0;
	}
	storageCode.textInput.editable=false;
	salerCode.txtContent.setFocus();
	
	//阻止放大镜输入
	preventDefaultForm();
}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	salerCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	});
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.imageList1, toolBar.btCancel, toolBar.btSave, toolBar.imageList2, toolBar.btQuery, toolBar.imageList6, toolBar.btExit]
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
 * 清空表单
 */
private function clearForm(masterFlag:Boolean, detailFlag:Boolean):void
{
	if (masterFlag)
	{
		salerCode.txtContent.text="";
		beginBillDate.selectedDate=new Date();
		endBillDate.selectedDate=new Date();
	}
	if (detailFlag)
	{
		gdItems.dataProvider=new ArrayCollection();
	}
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
	boolean=!boolean;
	storageCode.enabled=boolean;
	salerCode.enabled=boolean;
	beginBillDate.enabled=boolean;
	endBillDate.enabled=boolean;
}



/**
 * 供应单位字典
 */
protected function salerCode_queryIconClickHandler(event:Event):void
{
	//根据仓库编码和单位编码到仓库字典中查对应的 所属部门；
	var ro:RemoteObject = RemoteUtil.getRemoteObject('centerStorageImpl',function(rev1:Object):void{
		if(rev1.data){
			var x:int=0;
			MaterialDictShower.showProviderDict(function(rev:Object):void
			{
				salerCode.txtContent.text=rev.providerName;
				_condition.salerCode=rev.providerId;
			}, x, _winY,rev1.data[0].deptCode);
		}
	});
	ro.findStorageById(storageCode.selectedItem.storageCode);
}

/**
 * 验证表体明细
 * */
private function validateDetail(ary:ArrayCollection):Boolean
{
	var isSucess:Boolean=true;
	if (ary.length == 0)
	{
		isSucess=false;
		Alert.show('请选择要保存的记录', '提示');
		return isSucess;
	}
	
	//ryh 2013.01.23东方医院
	var _invoiceNo:String="";
	if(_isSelected)
	{
		for each (var obj:Object in ary)
		{
			if(obj.invoiceNo && _invoiceNo=="")
			{
				_invoiceNo=obj.invoiceNo;
			}
			if(obj.invoiceNo && _invoiceNo!="" && obj.invoiceNo!=_invoiceNo)
			{
				Alert.show('保存记录中有不相同的发票号', '提示');
				isSucess=false;
				return isSucess;
			}
		}
	}
	
	
	for each (var it:Object in ary)
	{
		//ryh 2013.01.23东方医院
		if(_isSelected)
		{
			if(it.isGive !='1')
			{
				it.invoiceNo=_invoiceNo;
			}
		}
		
		if (it.tradePrice1 == '' || it.tradePrice1 == null)
		{
			Alert.show('第' + it.serialNo + '行的"进价"为空，请填写完整', '提示');
			isSucess=false;
			break;
		}
		//ryh 2012.10.19，赠送耗材不需要填写发票号
		if (it.isGive !='1')
		{
			if((it.invoiceNo == '' || it.invoiceNo == null))
			{
				Alert.show('第' + it.serialNo + '行的"发票号"为空，请填写完整', '提示');
				isSucess=false;
				break;
			}
			if (it.acctAmount == '' || it.acctAmount == null)
			{
				Alert.show('第' + it.serialNo + '行的"票面数量"为空，请填写完整', '提示');
				isSucess=false;
				break;
			}
			
		}
	}
	return isSucess;
}

/**
 * 查询前验证表头
 */
private function validateMaster():Boolean
{
	if (storageCode.selectedIndex == -1)
	{
		storageCode.setFocus();
		Alert.show("仓库必选", "提示");
		return false;
	}
	if (salerCode.txtContent.text == "")
	{
		salerCode.txtContent.setFocus();
		Alert.show("供应单位必填", "提示");
		return false;
	}
	return true;
}

/**
 * 进价金额=进价*票面数量
 */
private function labFun(item:Object, column:DataGridColumn):*
{
	item.tradeMoney=item.tradePrice * item.acctAmount;
	return item.tradeMoney;
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
	var excelTitle:String='采购入库单'+_currentDate;
	file.save(mbytes,excelTitle+".xls");
}
/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	setPrintPageSize();
	//
	var laryDataList1:ArrayCollection=gdItems.dataProvider as ArrayCollection;
	var laryDataList:ArrayCollection = ObjectUtil.copy(laryDataList1) as ArrayCollection;
	preparePrintData(laryDataList);
	var rawData:ArrayCollection = gdItems.getRawDataProvider() as ArrayCollection;
	var lastItem:Object=rawData.getItemAt(rawData.length - 1);
	for each (var item:Object in laryDataList)
	{
		if (item.factoryName)
		{
			item.factoryName=item.factoryName.substr(0, 5);
		}
		item.invoiceNo = item.invoiceNo == null ? "" : item.invoiceNo;
		item.materialSpec = item.materialSpec == null ? "" : item.materialSpec;
		item.nameSpec = item.materialName + (item.packageSpec == null ? (item.materialSpec == null ? "" :item.materialSpec):item.packageSpec );
	}
	var dict:Dictionary=new Dictionary();
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="采购入库单";
	dict["制表"]=AppInfo.currentUserInfo.userName;
	dict["仓库"]=storageCode.textInput.text;
	dict["进货单位"]=salerCode.txtContent.text;
	dict["入库日期"]=beginBillDate.text;
	dict["进价金额"]=lastItem.tradeMoney;
	dict["日期范围"]="      从 " + beginBillDate.text + " 到 " + endBillDate.text + "";
	dict["表尾第一行"]="从：xxxx"
	dict["表尾第二行"]="到：xxxx"
	var lstrReportFile:String="report/materialAcct/daily/receiveReport/receiveList.xml";
	loadReportXml(lstrReportFile, laryDataList, dict,printSign)
}

private function loadReportXml(reportUrl:String,faryDetails:ArrayCollection, fdict:Dictionary,fprintSign:String):void{
	var loader:UrlLoader=new UrlLoader();
	loader.addEventListener(Event.COMPLETE, function(event:Event):void{
		var xml:XML=XML(event.currentTarget.Data)
		if(ReportParameter.reportPrintHeight_in&&ReportParameter.reportPrintHeight_in!='0'){
			var lreportHeight:String=parseFloat(ReportParameter.reportPrintHeight_in)/10+''
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
	setPrintPageToDefault();
}
private function preparePrintData(faryData:ArrayCollection):void
{
	for (var i:int=0; i < faryData.length; i++)
	{
		var item:Object=faryData.getItemAt(i);
		item.factoryName=!item.factoryName ? '' : item.factoryName
		item.pageNo=int(i / PAGE_SIZE) + 1
		//
		item.wholeSalePrice = item.amountPerPackage * item.wholeSalePrice; //
		item.retailPrice = item.amountPerPackage * item.retailPrice; //
		item.tradePrice = item.amountPerPackage * item.tradePrice; //
		item.invitePrice = item.amountPerPackage * item.invitePrice; //
		item.packageUnits = item.packageUnits == null ? item.materialUnits:item.packageUnits
	}
}

/**
 * 修改按钮
 */
protected function toolBar_modifyClickHandler(event:Event):void
{
//	//修改权限
//	if (!checkUserRole('02'))
//	{
//		return;
//	}
//	//判断当前表格是否具有明细数据
//	var laryDetails:ArrayCollection=gdItems.dataProvider as ArrayCollection;
//	if (!laryDetails)
//	{
//		return;
//	}
//	//修改按钮初始化
//	toolBar.modifyToPreState();
//	//表头设置可写
//	setReadOnly(false);
//	gdItems.editable=true;
}
private function labFunRowNo(item:Object,column:DataGridColumn):String{
	var ary:ArrayCollection = gdItems.dataProvider as ArrayCollection;
	var currentNo:int = ary.getItemIndex(item) + 1;
	item.rowNo = currentNo;
	if(item.notData){
		return '合计'
	}
	return currentNo.toString();
}
/**
 * 保存按钮
 */
protected function toolBar_saveClickHandler(event:Event):void
{
	//保存权限
	if (!checkUserRole('04'))
	{
		return;
	}
	//提示确定保存
	Alert.show("您确定保存？", "提示", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
	{
		if (e.detail == Alert.NO)
		{
			return;
		}
		var laryDetails:ArrayCollection=gdItems.dataProvider as ArrayCollection;
		var laryDetailsNew:ArrayCollection=new ArrayCollection();
		laryDetails = createSelectedItems(laryDetails);
		if (!validateDetail(laryDetails))
		{
			return;
		}
		//byzcl
		for each(var item:Object in laryDetails){
			if(item.patientId != null){
				for each(var item1:Object in laryNew){
					if(item1.patientId == item.patientId && item1.materialCode == item.materialCode){
						item1.invoiceNo = item.invoiceNo;
						laryDetailsNew.addItem(item1);
					}
				}
			}else{
				for each(var item2:Object in laryNew){
					if(item2.materialCode == item.materialCode && item2.serialNo == item.serialNo && item2.mainAutoId == item.mainAutoId){//item2.invoiceNo ==null && 
						item2.invoiceNo = item.invoiceNo;
						laryDetailsNew.addItem(item2);
					}
				}
			}
		}
		
		var i:int = 0;
		var errorItem:Object = null;
		for each(var item:Object in laryDetailsNew){//byzcl
			i ++ ;
			//包装系数不存在或为0，提示用户
			if(!item.amountPerPackage || item.amountPerPackage == 0 ){
				Alert.show('第'+item.rowNo+'条明细的包装系数为0','提示');
				break;
			}
			//赠送耗材不需要计算票面数量 ryh 2012.10.19
			if(item.tradePrice1/item.amountPerPackage != item.wholeSalePrice || (item.isGive!='1' && item.amount != item.amountPerPackage * item.acctAmount1)){
				errorItem = item;
				isSave = false;
				break;
			}else{
				item.tradePrice = item.tradePrice1/item.amountPerPackage;
				isSave = true;
			}
		}
		//
		if(!isSave){
			//提示确定保存
			Alert.show('请检查第'+errorItem.rowNo+'条的进价、批发价，票面数量、入库数量是否相等','提示');
			gdItems.selectedIndex = Number(errorItem.rowNo) - 1;
			return;
		}
		//
		toolBar.btSave.enabled=false;
		var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
		{
			toolBar.saveToPreState();
			Alert.show("采购入库单保存成功！", "提示信息");
			//
//			removeItemFromGrid();
			toolBar.setEnabled(storageCode, false);
			toolBar.setEnabled(salerCode, false);
			toolBar.setEnabled(toolBar.btSave, false);
			toolBar.setEnabled(toolBar.btModify, false);
			toolBar.setEnabled(toolBar.btCancel, true);
			changeItemColor();
			return;
		});
		ro.save(laryDetailsNew);
		return;
		
	});
}
/**
 * 保存完后将勾选的物资从表格中移除掉
 * */
private function removeItemFromGrid():void{
	var lary:ArrayCollection = gdItems.dataProvider as ArrayCollection;
	var j:int = 0;
	for each(var selectedItem:Object in lary){
		if(selectedItem.isSelected){
			lary.removeItemAt(j);
			gdItems.dataProvider = lary;
			removeItemFromGrid();
		}else{
			continue;
		}
		j ++;
	}
//	return lary;
}

private function changeItemColor():void{
	var lary:ArrayCollection = gdItems.dataProvider as ArrayCollection;
	for each(var o:Object in lary){
		if(o.isSelected){
			o.currentStatus ="2";
		}
		var factoryObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict,'provider',o.factoryCode);
		o.factoryName=factoryObj==null ? "" : factoryObj.providerName;
		
		ListCollectionView(lary).itemUpdated(o, "currentStatus");
	}
}
/**
 * 放弃按钮
 */
protected function toolBar_cancelClickHandler(event:Event):void
{
	toolBar.cancelToPreState();
	storageCode.enabled = true;
	salerCode.enabled = true;
	//清空当前表单
	clearForm(true, true);
	//设置只读
	setReadOnly(false);
}

///**
// * 输入发票号查询时，验证表格中是否存在要查询的发票号
// * */
//private function hasSameInvoiceNo(fInvoiceNo:String,gridItems:ArrayCollection =null):Boolean{
//	var bool:Boolean = false;
//	for each(var item:Object in gridItems ){
//		if(item.invoiceNo == fInvoiceNo){
//			bool = true;
//			break;
//		}
//	}
//	return bool;
//}
///**
// * 若存在相同的发票号，则从列表中过滤，不查询后台
// * */
//private function filterByInvoiceNo(fstrInvoiceNo:String,faryItems:ArrayCollection):ArrayCollection{
//	var i:int = 0;
//	for each(var it:Object in faryItems){
//		if(it.invoiceNo != fstrInvoiceNo){
//			faryItems.removeItemAt(i);
//			i++;
//			filterByInvoiceNo(fstrInvoiceNo,faryItems);
//		}
//	}
//	return faryItems;
//}
/**
 * 查询按钮
 */
protected function toolBar_queryClickHandler(event:Event):void
{
	if (!validateMaster())
	{
		return;
	}
	//
	//
	var paramQuery:ParameterObject=new ParameterObject();
	//仓库
	if (storageCode.selectedItem != null && storageCode.selectedIndex > -1)
	{
		_condition.storageCode=storageCode.selectedItem.storageCode;
	}
	_condition.rdFlag="1"
	_condition.isGive=isGive.selected ? '1' : '0';
	//入库日期
	_condition.startDate=DateField.dateToString(beginBillDate.selectedDate, 'YYYY-MM-DD');
	_condition.endDate=DateField.dateToString(endBillDate.selectedDate, 'YYYY-MM-DD');
	paramQuery.conditions=_condition;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
	{
		registerClassAlias("cn.superion.material.entity.MaterialRdsDetail", cn.superion.vo.material.MaterialRdsDetail);
		if (rev.data && rev.data.length > 0)
		{
			var lary:ArrayCollection = rev.data as ArrayCollection;
			laryNew = ObjectUtil.copy(rev.data as ArrayCollection) as ArrayCollection;//byzcl
			//laryArray = laryNew.toArray().slice();
			
			var list:ArrayCollection=new ArrayCollection();
			var signFk:Boolean=false;
			for each(var item:Object in lary){
				item.acctAmount1 = item.acctAmount == null ? item.packageAmount:item.acctAmount / item.amountPerPackage;
				var factoryObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict,'provider',item.factoryCode);
				item.factoryName=factoryObj==null ? "" : factoryObj.providerName;
//				item.tradePrice1 = item.tradePrice * item.amountPerPackage;
				item.tradePrice1 = item.wholeSalePrice * item.amountPerPackage;//根据郑工所说，改为批发价 8-15
			}
			
			for each(var item:Object in laryNew){
				item.acctAmount1 = item.acctAmount == null ? item.packageAmount:item.acctAmount / item.amountPerPackage;
				var factoryObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict,'provider',item.factoryCode);
				item.factoryName=factoryObj==null ? "" : factoryObj.providerName;
				//				item.tradePrice1 = item.tradePrice * item.amountPerPackage;
				item.tradePrice1 = item.wholeSalePrice * item.amountPerPackage;//根据郑工所说，改为批发价 8-15
			}
			
			//实现汇总的功能都在这个循环里面 byzcl
			for each(var item2:Object in lary){
			var dl:Number=0;
			var dl1:Number=0;
			var dl2:Number=0;
			var dl3:Number=0;
			var dl4:Number=0;
			var dl5:Number=0;
			var dl6:Number=0;
			if(item2.patientId != null){
				for(var j:int=0;j<list.length;j++){
					if(list.getItemAt(j)[0] == item2.patientId && list.getItemAt(j)[1] == item2.materialId){
						signFk = true;
						continue;
					}
				}
				if(signFk){
					signFk = false;
					continue;
				}
				item2.sumMoney = item2.retailMoney;
				dl = item2.retailMoney;
				dl1 = item2.wholeSaleMoney;
				dl2 = item2.packageAmount;
				dl3 = item2.acctAmount1;
				dl4 = item2.tradeMoney;
				dl5 = item2.inviteMoney;
				dl6 = item2.retailMoney;
				for each(var item1:Object in lary){
					if(item1.patientId != null){
						if(item1.patientId == item2.patientId && item1.materialId == item2.materialId){
							item2.sumMoney += item1.retailMoney;
							item2.wholeSaleMoney += item1.wholeSaleMoney;
							item2.packageAmount += item1.packageAmount;
							item2.acctAmount1 += item1.acctAmount1;
							item2.tradeMoney += item1.tradeMoney;
							item2.inviteMoney += item1.inviteMoney;
							item2.retailMoney += item1.retailMoney;
							item1.canelSign='1';
						}
					}
				}
				item2.sumMoney -= dl;
				item2.wholeSaleMoney -= dl1;
				item2.packageAmount -= dl2;
				item2.acctAmount1 -= dl3;
				item2.tradeMoney -= dl4;
				item2.inviteMoney -= dl5;
				item2.retailMoney -= dl6;
				item2.canelSign='0';
				var patientId:Array = [];
				patientId[0] = item2.patientId;
				patientId[1] = item2.materialId;
				list.addItem(patientId);
			}
			}
			//删除多余的明细 byzcl
			for(var i:int=0;i<lary.length;i++){
				if(lary.getItemAt(i).patientId != null && lary.getItemAt(i).canelSign =='1'){
					lary.removeItemAt(i);
					i=-1;
				}
			}
			//			var rawList:ArrayCollection =  gdItems.dataProvider as ArrayCollection;
			//			var newAry:ArrayCollection = appendDataToGrid(lary,rawList);
			gdItems.dataProvider = lary;
			toolBar.setEnabled(storageCode, false);
			toolBar.setEnabled(salerCode, false);
			toolBar.setEnabled(toolBar.btSave, true);
			toolBar.setEnabled(toolBar.btModify, true);
			toolBar.setEnabled(toolBar.btCancel, true);
			gdItems.editable = true;
//			gdItems.sortableColumns = true;
			return;
		}
		gdItems.dataProvider=[];
	});
	ro.findByCondition(paramQuery);
}

/**
 * 过滤出选中的项目
 * */
private function createSelectedItems(faryReceive:ArrayCollection):ArrayCollection{
	var selectedItems:ArrayCollection = new ArrayCollection();
	for each (var item:Object in faryReceive)
	{
		if(item.isSelected)
		{
			selectedItems.addItem(item);
		}
	}
	return selectedItems;
}
///**
// * 将不同发票号的数据，追加到列表中
// * */
//private function appendDataToGrid(fary:ArrayCollection,rawAry:ArrayCollection):ArrayCollection{
//	if(rawAry.length ==0){
//		rawAry.addAll(fary);
//	}else{
//		for each(var item:Object in fary){
//			if(hasSameInvoiceNo(item.invoiceNo,rawAry)){
//				continue;
//			}
//			rawAry.addItem(item);
//		}
//	}
//	return rawAry;
//}
/**
 * 退出按钮
 */
protected function toolBar_exitClickHandler(event:Event):void
{
	PopUpManager.removePopUp(IFlexDisplayObject(this.parentDocument));
	DefaultPage.gotoDefaultPage();
}

/**
 * LabFunction 处理售价显示
 */
private function retailPriceLBF(item:Object, column:DataGridColumn):String
{
	//若存在包装系数，则返回 包装系数 * 包装数量
	if(item.amountPerPackage && item.amountPerPackage!='0'){
		return (item.amountPerPackage * item.retailPrice).toFixed(2);
	}else{
		return item.retailPrice == null ? "":(item.retailPrice).toFixed(2);
	}
}
/**
 * LabFunction 票面数量
 */
private function acctAmountLBF(item:Object, column:DataGridColumn):String
{
	return item.packageAmount == null ? "": (item.packageAmount).toFixed(2);;
}
/**
 * LabFunction 处理批发价显示
 */
private function wholeSalePriceLBF(item:Object, column:DataGridColumn):String
{
	//若存在包装系数，则返回 包装系数 * 包装数量
	if(item.amountPerPackage && item.amountPerPackage!='0'){
		return (item.amountPerPackage * item.wholeSalePrice).toFixed(2);
	}else{
		return item.wholeSalePrice == null ? "": (item.wholeSalePrice).toFixed(2);;
	}
}
/**
 * LabFunction 处理进价显示
 */
private function tradePriceLBF(item:Object, column:DataGridColumn):String
{
	//若存在包装系数，则返回 包装系数 * 包装数量
	if(item.amountPerPackage && item.amountPerPackage!='0'){
		return (item.amountPerPackage * item.tradePrice).toFixed(2);
	}else{
		return item.tradePrice == null ? "": (item.tradePrice).toFixed(2);;
	}
}
/**
 * LabFunction 处理中标价显示
 */
private function invitePriceLBF(item:Object, column:DataGridColumn):String
{
	//若存在包装系数，则返回 包装系数 * 包装数量
	if(item.amountPerPackage && item.amountPerPackage!='0'){
		return (item.amountPerPackage * item.invitePrice).toFixed(2);
	}else{
		return item.invitePrice == null ? "": (item.invitePrice).toFixed(2);;
	}
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
