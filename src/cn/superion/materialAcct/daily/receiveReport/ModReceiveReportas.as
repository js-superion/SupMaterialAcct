
/**
 *		 入库单报告模块
 *		 author:周作建   2011.06.01
 *		 checked by：
 **/


import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.base.util.StringUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialAcct.util.DefaultPage;
import cn.superion.materialAcct.util.MaterialDictShower;
import cn.superion.materialAcct.util.ReportParameter;
import cn.superion.materialAcct.util.ToolBar;
import cn.superion.report.hlib.UrlLoader;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialRdsAcctMaster;
import cn.superion.vo.material.MaterialRdsDetail;
import cn.superion.vo.system.SysUnitInfor;

import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

import spark.events.TextOperationEvent;

registerClassAlias("cn.superion.material.entity.MaterialRdsAcctMaster", cn.superion.vo.material.MaterialRdsAcctMaster);

public static const DESTINATION:String="materialAcctReceiveImpl";
//菜单号
public static const MENU_NO:String="0103";
//条件对象
private static var _condition:Object={};

private var _currentRdsAcctMaster:MaterialRdsAcctMaster
private var _winY:int=0;
private var PAGE_SIZE:int=10;
private var laryNew:ArrayCollection=new ArrayCollection();
/**
 * 初始化当前窗口
 * */
private function doInit():void
{
	parentDocument.title="入库报告单";
	_winY=this.parentApplication.screen.height - 345;
	initPanel();
	setPrintPageSize();
	
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
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1, toolBar.btCancel, toolBar.btSave, toolBar.imageList2, toolBar.btQuery, toolBar.imageList6, toolBar.btExit]
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
				_condition.salerName=rev.providerName;
			}, x, _winY,rev1.data[0].deptCode);
		}
	});
	ro.findStorageById(storageCode.selectedItem.storageCode);
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
	var excelTitle:String='入库报告单'+_currentDate;
	file.save(mbytes,excelTitle+".xls");
}
/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	setPrintPageSize();
	var laryDataList:ArrayCollection=gdItems.dataProvider as ArrayCollection;
	_currentRdsAcctMaster=_currentRdsAcctMaster ? _currentRdsAcctMaster : new MaterialRdsAcctMaster()
	preparePrintData(laryDataList);
	var dict:Dictionary=new Dictionary();
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="入库报告单";
	dict["制表人"]=AppInfo.currentUserInfo.userName;
	dict["仓库"]= ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict,'storage',_currentRdsAcctMaster.storageCode).storageName;
	if(isGive.selected){
		dict["仓库"]=dict["仓库"]+'(zs)'
	}
	dict["进货单位"]=_currentRdsAcctMaster.salerName.substr(0,17);
	dict["入库日期"]=beginBillDate.text;
	dict["日期范围"]="从" + beginBillDate.text + " 到 " + endBillDate.text + "";
	dict["表尾第一行"]=createPrintFirstBottomLine();
	dict["表尾第二行"]=createPrintSecondBottomLine();
	dict["起始号"]= laryDataList.length > 0 ? laryDataList[0].rdBillNo:"";
	dict["结束号"]= laryDataList.length > 0 ? laryDataList[laryDataList.length - 1 ].rdBillNo:"";
	var lstrReportFile:String="report/materialAcct/daily/receiveReport/receive2.xml";
	loadReportXml(lstrReportFile, laryDataList, dict,printSign)
}

/**
 * 加载报表xml修改高度并打印
 * */
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
		
		item.wholeSalePrice = item.amountPerPackage * item.wholeSalePrice; //
		item.retailPrice = item.amountPerPackage * item.retailPrice; //
		item.tradePrice = item.amountPerPackage * item.tradePrice;
		
		item.factoryName=!item.factoryName ? '' : item.factoryName
		item.pageNo=pageNo;
		item.factoryName = item.factoryName.substr(0,6);
		item.packageUnits = item.packageUnits == null ? item.materialUnits : item.packageUnits;
		item.nameSpec = item.materialName+"  " + (item.packageSpec == null ? (item.materialSpec == null ? "" :item.materialSpec):item.packageSpec );
		item.invoiceNo = item.invoiceNo == null ? "":item.invoiceNo;
		item.packageUnits = item.packageUnits == null ? item.materialUnits:item.packageUnits;
	}
}



private function createPrintFirstBottomLine():String
{
	var lstrLine:String="    批发总额：{1}     进价总额：{2}          零售总额：{3}";
	lstrLine=StringUtils.format(lstrLine, _currentRdsAcctMaster.minRdBillNo, 
		(_currentRdsAcctMaster.wholeSaleSum ).toFixed(2), 
		(_currentRdsAcctMaster.tradeSum).toFixed(2), 
		(_currentRdsAcctMaster.retailSum ).toFixed(2))
	return lstrLine
}

private function createPrintSecondBottomLine():String
{
	var accounter:Object = ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',_currentRdsAcctMaster.accounter) ;
	var lstrLine:String="    主任：{1}        采购：{2}         保管：{3}       会计：{4}      批零差：{5}";
	lstrLine=StringUtils.format(lstrLine, 
		_currentRdsAcctMaster.maxRdBillNo,
		"",
		"",
		"",
		accounter?accounter.personIdName:"",
		(_currentRdsAcctMaster.retailSum - _currentRdsAcctMaster.wholeSaleSum).toFixed(2))
	return lstrLine;
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
	var param:ParameterObject=new ParameterObject();
	if (storageCode.selectedItem != null && storageCode.selectedIndex > -1)
	{
		_condition.storageCode=storageCode.selectedItem.storageCode;
	}
	//按供应单位
	_condition.salerSign="1";
	//入库日期
	_condition.startDate=DateField.dateToString(beginBillDate.selectedDate, 'YYYY-MM-DD');
	_condition.endDate=DateField.dateToString(endBillDate.selectedDate, 'YYYY-MM-DD');

	param.conditions=_condition;

	var laryDetails:ArrayCollection=laryNew;//gdItems.dataProvider as ArrayCollection;//byzcl
	toolBar.btSave.enabled=false;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
	{
		if (rev && rev.data[0])
		{
			_currentRdsAcctMaster=rev.data[0].master as MaterialRdsAcctMaster
			for each(var item:Object in rev.data[0].detail){
				var factoryObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict,'provider',item.factoryCode);
				item.factoryName=factoryObj==null ? "" : factoryObj.providerName;
			}
			//gdItems.dataProvider=rev.data[0].detail as ArrayCollection
			toolBar.saveToPreState();
			toolBar.setEnabled(toolBar.btSave, false);
			toolBar.setEnabled(toolBar.btPrint, true);
			toolBar.setEnabled(toolBar.btExp, true);
			toolBar.setEnabled(toolBar.btCancel, true);
			
			Alert.show("入库报告单保存成功！", "提示信息");
			return;
		}
	});
	ro.saveReport(param, laryDetails);
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
}

/**
 * 查询按钮
 */
protected function toolBar_queryClickHandler(event:Event):void
{
	if (!validateMaster())
	{
		return;
	}
	var paramQuery:ParameterObject=new ParameterObject();
	//仓库
	if (storageCode.selectedItem != null && storageCode.selectedIndex > -1)
	{
		//_condition['storageCode']=storageCode.selectedItem.storageCode;
		_condition.storageCode=storageCode.selectedItem.storageCode;
	}
	_condition.isGive=isGive.selected ? '1' : '0';
	//入库日期
	_condition.startDate=DateField.dateToString(beginBillDate.selectedDate, 'YYYY-MM-DD');
	_condition.endDate=DateField.dateToString(endBillDate.selectedDate, 'YYYY-MM-DD');
	_condition.invoiceNo = invoiceNo.text;

	paramQuery.conditions=_condition;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
	{
		registerClassAlias("cn.superion.material.entity.MaterialRdsDetail", cn.superion.vo.material.MaterialRdsDetail);
		
		if (rev.data && rev.data.length > 0)
		{
			var lary:ArrayCollection = rev.data as ArrayCollection;
			for each(var item:Object in lary){
				var factoryObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict,'provider',item.factoryCode);
				item.factoryName=factoryObj==null ? "" : factoryObj.providerName;
				item.newAcctAmount = item.acctAmount * item.amountPerPackage; 
			}
			laryNew = ObjectUtil.copy(lary) as ArrayCollection;//byzcl
			var patientId:String = null;
			var materialId:String = null;
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
					if(patientId == item2.patientId && materialId == item2.materialId){
						continue;
					}
					item2.sumMoney = item2.retailMoney;
					dl = item2.retailMoney;
					dl1 = item2.wholeSaleMoney;
					dl2 = item2.packageAmount;
					dl3 = item2.acctAmount;
					dl4 = item2.tradeMoney;
					dl5 = item2.inviteMoney;
					dl6 = item2.retailMoney;
					for each(var item1:Object in lary){
						if(item1.patientId != null){
							if(item1.patientId == item2.patientId && item1.materialId == item2.materialId){
								item2.sumMoney += item1.retailMoney;
								item2.wholeSaleMoney += item1.wholeSaleMoney;
								item2.packageAmount += item1.packageAmount;
								item2.acctAmount += item1.acctAmount;
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
					item2.acctAmount -= dl3;
					item2.tradeMoney -= dl4;
					item2.inviteMoney -= dl5;
					item2.retailMoney -= dl6;
					item2.canelSign='0';
					patientId = item2.patientId;
					materialId = item2.materialId;
				}
			}
			//删除多余的明细 byzcl
			for(var i:int=0;i<lary.length;i++){
				if(lary.getItemAt(i).patientId != null && lary.getItemAt(i).canelSign =='1'){
					lary.removeItemAt(i);
					i=-1;
				}
			}
			gdItems.dataProvider = lary;
			toolBar.setEnabled(toolBar.btSave, true);
			toolBar.setEnabled(storageCode, false);
			toolBar.setEnabled(salerCode, false);
			toolBar.setEnabled(toolBar.btCancel, true);
			return;
		}
		gdItems.dataProvider=[];
	});
	ro.findReportByCondition(paramQuery);
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
 * LabFunction 处理进价显示
 */
private function tradePriceLBF(item:Object, column:DataGridColumn):String
{
	//若存在包装系数，则返回 包装系数 * 包装数量
	if(item.amountPerPackage && item.amountPerPackage!='0'){
		return (item.amountPerPackage * item.tradePrice).toFixed(2);
	}else{
		return item.retailPrice == null ? "":(item.tradePrice).toFixed(2);
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
		return item.invitePrice == null ? "":(item.invitePrice).toFixed(2);
	}
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
 * 退出按钮
 */
protected function toolBar_exitClickHandler(event:Event):void
{
	PopUpManager.removePopUp(IFlexDisplayObject(this.parentDocument));
	DefaultPage.gotoDefaultPage();
	setPrintPageToDefault();
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