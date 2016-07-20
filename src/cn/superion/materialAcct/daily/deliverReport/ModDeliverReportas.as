
/**
 *		 出库单报告模块
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
import cn.superion.dataDict.MaterialDictWin;
import cn.superion.materialAcct.util.DefaultPage;
import cn.superion.materialAcct.util.MaterialDictShower;
import cn.superion.materialAcct.util.ReportParameter;
import cn.superion.materialAcct.util.ToolBar;
import cn.superion.report.hlib.UrlLoader;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
//import cn.superion.vo.material.DeliverReportAcct;
import cn.superion.vo.material.MaterialRdsAcctMaster;
import cn.superion.vo.material.MaterialRdsDetail;
import cn.superion.vo.system.SysUnitInfor;

import com.adobe.utils.ArrayUtil;
import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;
import mx.utils.ObjectUtil;

import spark.events.TextOperationEvent;

registerClassAlias("cn.superion.material.entity.MaterialRdsAcctMaster", cn.superion.vo.material.MaterialRdsAcctMaster);
registerClassAlias("cn.superion.material.entity.MaterialRdsDetail", cn.superion.vo.material.MaterialRdsDetail);

public static const DESTINATION:String="materialAcctDeliverImpl";
//菜单号
public static const MENU_NO:String="0104";
//条件对象
private static var _condition:Object={};

private var _currentRdsAcctMaster:MaterialRdsAcctMaster
private var PAGE_SIZE:int=10;
//private var deliverReport:DeliverReportAcct=new DeliverReportAcct();
private var laryNew:ArrayCollection=new ArrayCollection();


/**
 * 初始化当前窗口
 * */
private function doInit():void
{
	parentDocument.title="出库报告单";
	initPanel();
	setPrintPageSize();
	MaterialDictShower.getAdvanceDictList();
	
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
	//授权仓库赋值
	if (AppInfo.currentUserInfo.storageList != null && AppInfo.currentUserInfo.storageList.length > 0)
	{
		storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
		storageCode.selectedIndex=0;
	}
	//
	storageCode.textInput.editable=false;

	deptCode.txtContent.setFocus();
	//阻止放大镜输入
	preventDefaultForm();
}
/**
 * 单据编号
 */ 
public function billNoList(ckname:String):ArrayCollection
{
	var billArrayList:ArrayCollection=new ArrayCollection();
	var paramQuery:ParameterObject=new ParameterObject();
	var comdition:Object={};
	//仓库
	if (storageCode.selectedItem != null && storageCode.selectedIndex > -1)
	{
		comdition.storageCode=storageCode.selectedItem.storageCode;
	}
	//入库日期
	comdition.startDate=DateField.dateToString(beginBillDate.selectedDate, 'YYYY-MM-DD');
	comdition.endDate=DateField.dateToString(endBillDate.selectedDate, 'YYYY-MM-DD');
	comdition.deptCode=ckname;
	comdition..specialSign=specialSign.selected ? "1" : "";
	
	paramQuery.conditions=comdition;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
	{
		for(var i:int=0;i<rev.data.length;i++)
		{
			var billObj:Object=[];
			billObj["billNo"]=rev.data[i];
			billArrayList.addItem(billObj);
		}
	});
	ro.findReportByCondition1(paramQuery);
	
	return billArrayList;
}
/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	deptCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
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
		deptCode.txtContent.text="";
		beginBillDate.selectedDate=new Date();
		endBillDate.selectedDate=new Date();
	}
	if (detailFlag)
	{
		gdItems.dataProvider=new ArrayCollection();
	}
}
/**
 * 单据编号改变触发
 * */
protected function billNo_changeHandler(event:IndexChangeEvent):void
{
	toolBar_queryClickHandler(null);
}
/**
 * 部门字典
 * */
protected function deptCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	MaterialDictShower.showDeptDict((function(rev:Object):void
	{
		deptCode.txtContent.text=rev.deptName;
		_condition.deptCode=rev.deptCode;
		_condition.deptName=rev.deptName;
		billNo.dataProvider=billNoList(rev.deptCode);
	}), x, y);
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
	if (deptCode.txtContent.text == "")
	{
		deptCode.txtContent.setFocus();
		Alert.show("部门必填", "提示");
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
	if(specialSign.selected)
	{
		//特殊高值打印
		printReportValue("1");
	}
	else
	{
		printReport("1");
	}
	

}

protected function toolBar_expClickHandler(event:Event):void
{
	//输出权限
	if (!checkUserRole('08'))
	{
		return;
	}
	if(specialSign.selected)
	{
		makeExport(gdItemsValue);
	}
	else
	{
		makeExport(gdItems);
	}
	
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
/**
 * 打印预览报表
 */
private function printReport(printSign:String):void
{
	setPrintPageSize();
	var laryDataList:ArrayCollection=gdItemsValue.dataProvider as ArrayCollection;
	preparePrintData(laryDataList);
	for each (var item:Object in laryDataList){
		item.detailRemark = item.detailRemark == null ? "" : item.detailRemark;
	}
//	for each (var item:Object in laryDataList){
//		if(item.factoryName){
//			item.factoryName = item.factoryName.substr(0,5);
//		}
//		item.nameSpec = item.materialName + (item.materialSpec == null ? "" : item.materialSpec);
//	}
	_currentRdsAcctMaster=_currentRdsAcctMaster ? _currentRdsAcctMaster : new MaterialRdsAcctMaster()
	var dict:Dictionary=new Dictionary();
	var deptUnitsName:String = "";
	for each (var it:Object in MaterialDictShower.SYS_UNITS){
		if(it.unitsCode == _currentRdsAcctMaster.deptUnitsCode){
			deptUnitsName = it.unitsSimpleName;
			
		}
		
	}
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="出库报告单";
	dict["制表人"]=AppInfo.currentUserInfo.userName;
	dict["仓库"]=ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict,'storage',_currentRdsAcctMaster.storageCode).storageName;
	dict["请领单位"]=deptUnitsName; //领用科室所在的单位
	dict["请领部门"]=_currentRdsAcctMaster.deptName;
	dict["入库日期"]=beginBillDate.text; 
 
	dict["日期范围"]="      从" + beginBillDate.text + " 到 " + endBillDate.text + "";
	dict["表尾第一行"]=createPrintFirstBottomLine()
	dict["表尾第二行"]=createPrintSecondBottomLine()
	dict["起始号"]= laryDataList.length > 0 ? laryDataList[0].rdBillNo:"";
	dict["结束号"]= laryDataList.length > 0 ? laryDataList[laryDataList.length - 1 ].rdBillNo:"";
	var lstrReportFile:String = "report/materialAcct/daily/deliverReport/deliverReport.xml";
	loadReportXml(lstrReportFile, laryDataList, dict,printSign)
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
private function createPrintSecondBottomLine():String
{
	var accounter:Object = ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',_currentRdsAcctMaster.accounter) ;
	var lstrLine:String="    会计：{0}       保管：{1}       经领人：{2}      制单：{3}";
	lstrLine=StringUtils.format(lstrLine, 
		accounter == null ? "" : accounter.personIdName,
		"",
		"",
		accounter == null ? "" : accounter.personIdName)
	return lstrLine;
}
private function createPrintFirstBottomLine():String
{
	var lstrLine:String="    批发总额：{0}            零售总额：{1}           批零差额：{2} ";
	lstrLine=StringUtils.format(lstrLine,  
		( _currentRdsAcctMaster.wholeSaleSum).toFixed(2), 
		( _currentRdsAcctMaster.retailSum ).toFixed(2),
		(_currentRdsAcctMaster.retailSum - _currentRdsAcctMaster.wholeSaleSum).toFixed(2))
	
	return lstrLine
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
		item.currentPageNo=int(i / PAGE_SIZE) + 1
		item.factoryName=!item.factoryName ? '' : item.factoryName
		item.nameSpec = item.materialName +"  "+ (item.materialSpec == null ? "" : item.materialSpec);
		item.pageNums=pageNo;
	}
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
	_condition.salerSign="0";
	//入库日期
	_condition.startDate=DateField.dateToString(beginBillDate.selectedDate, 'YYYY-MM-DD');
	_condition.endDate=DateField.dateToString(endBillDate.selectedDate, 'YYYY-MM-DD');
	_condition.specialSign=specialSign.selected ? "1" : "";
	
	param.conditions=_condition;

	var laryDetails:ArrayCollection=laryNew;//gdItems.dataProvider as ArrayCollection;//byzcl
	//此时应在发放审核时处理，这里临时处理
	laryDetails = fillValueToAcctAmount(laryDetails);
	toolBar.btSave.enabled=false;
	
	if(specialSign.selected){
		//保存特殊高值耗材
		saveValueReport(param, laryDetails);
	}
	else
	{
		var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
		{
			if (rev && rev.data[0])
			{
				_currentRdsAcctMaster=rev.data[0].master as MaterialRdsAcctMaster
				
				for each(var item:Object in rev.data[0].detail)
				{
					var factoryObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict,'provider',item.factoryCode);
					item.factoryName=factoryObj==null ? "" : factoryObj.providerName;
					
					var deptObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict,'dept',item.wardCode);
					item.wardCode=deptObj ? deptObj.deptName : '';
				}
				
				var col:ArrayCollection=rev.data[0].detail as ArrayCollection;
				var arycol:ArrayCollection=new ArrayCollection(ArrayUtil.copyArray(col.source));
				gdItems.dataProvider=col;
				gdItemsValue.dataProvider=arycol;
				
				toolBar.saveToPreState();
				toolBar.setEnabled(toolBar.btSave, false);
				toolBar.setEnabled(toolBar.btPrint, true);
				toolBar.setEnabled(toolBar.btExp, true);
				toolBar.setEnabled(toolBar.btCancel, true);
				Alert.show("出库报告单保存成功！", "提示信息");
				return;
			}
		});
		ro.saveReport(param, laryDetails);
	}
	
}

private function saveValueReport(param:ParameterObject,laryDetails:ArrayCollection):void
{
	
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
	{
		if (rev && rev.data.length>0 && rev.data[0])
		{
			_currentRdsAcctMaster=rev.data[0].master as MaterialRdsAcctMaster;
			
			var larry:ArrayCollection=new ArrayCollection();
			for each(var item:Object in rev.data){
				var details:ArrayCollection=item.rdsDetails as ArrayCollection;
				for each(var detail:Object in details)
				{
					var factoryObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict,'provider',detail.factoryCode);
					detail.factoryName=factoryObj==null ? "" : factoryObj.providerName;
					
					var deptObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict,'dept',detail.wardCode);
					detail.wardName=deptObj ? deptObj.deptName : '';
					larry.addItem(detail);
				}
			}
			
			var col:ArrayCollection=larry as ArrayCollection;
			var arycol:ArrayCollection=new ArrayCollection(ArrayUtil.copyArray(col.source));
			//gdItems.dataProvider=col;
			gdItemsValue.dataProvider=arycol;
			
			toolBar.saveToPreState();
			toolBar.setEnabled(toolBar.btSave, false);
			toolBar.setEnabled(toolBar.btPrint, true);
			toolBar.setEnabled(toolBar.btExp, true);
			toolBar.setEnabled(toolBar.btCancel, true);
			Alert.show("出库报告单保存成功！", "提示信息");
			return;
		}
	});
	ro.saveReportValue(param, laryDetails);
}


private function printReportValue(printSign:String):void
{
	setPrintPageSize();
	var laryDataList:ArrayCollection=gdItemsValue.dataProvider as ArrayCollection;
	preparePrintData(laryDataList);
	for each (var item:Object in laryDataList){
		item.detailRemark = item.detailRemark == null ? "" : item.detailRemark;
	}
	//	for each (var item:Object in laryDataList){
	//		if(item.factoryName){
	//			item.factoryName = item.factoryName.substr(0,5);
	//		}
	//		item.nameSpec = item.materialName + (item.materialSpec == null ? "" : item.materialSpec);
	//	}
	_currentRdsAcctMaster=_currentRdsAcctMaster ? _currentRdsAcctMaster : new MaterialRdsAcctMaster()
	var dict:Dictionary=new Dictionary();
	var deptUnitsName:String = "";
	for each (var it:Object in MaterialDictShower.SYS_UNITS){
		if(it.unitsCode == _currentRdsAcctMaster.deptUnitsCode){
			deptUnitsName = it.unitsSimpleName;
			
		}
		
	}
	dict["单位名称"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	dict["主标题"]="出库报告单";
	dict["制表人"]=AppInfo.currentUserInfo.userName;
	dict["仓库"]=ArrayCollUtils.findItemInArrayByValue(BaseDict.storageDict,'storage',_currentRdsAcctMaster.storageCode).storageName;
	dict["请领单位"]=deptUnitsName; //领用科室所在的单位
	dict["请领部门"]=_currentRdsAcctMaster.deptName;
	dict["入库日期"]=beginBillDate.text;
	
	dict["日期范围"]="      从" + beginBillDate.text + " 到 " + endBillDate.text + "";
//	dict["表尾第一行"]=createPrintFirstBottomLineValue()
	dict["表尾第二行"]=createPrintSecondBottomLineValue() 
//	dict["起始号"]= laryDataList.length > 0 ? laryDataList[0].rdBillNo:"";
//	dict["结束号"]= laryDataList.length > 0 ? laryDataList[laryDataList.length - 1 ].rdBillNo:"";
	var lstrReportFile:String = "report/materialAcct/daily/deliverReport/deliverReportPats.xml";
	loadReportXml(lstrReportFile, laryDataList, dict,printSign)
}

private function createPrintSecondBottomLineValue():String
{
	var accounter:Object = ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',_currentRdsAcctMaster.accounter) ;
	var lstrLine:String="会计：{0}       保管：{1}       经领人：{2}      制单：{3}";
	lstrLine=StringUtils.format(lstrLine, 
		accounter == null ? "" : accounter.personIdName,
		"", 
		"",
		accounter == null ? "" : accounter.personIdName)
	return lstrLine;
}

/**
 * 将数量amount直接转为核算数量acctAmount
 * */
private function fillValueToAcctAmount(faryDetails:ArrayCollection):ArrayCollection{
	for each(var item:MaterialRdsDetail in faryDetails){
		item.acctAmount = item.amount;
	}
	return faryDetails;
}
/**
 * 放弃按钮
 */
protected function toolBar_cancelClickHandler(event:Event):void
{
	Alert.show("您是否放弃当前操作吗？", "提示", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
	{
		if (e.detail == Alert.NO)
		{
			return;
		}
		toolBar.cancelToPreState();
		storageCode.enabled = true;
		deptCode.enabled = true;
		//清空当前表单
		clearForm(true, true);
	});
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
		_condition.storageCode=storageCode.selectedItem.storageCode;
	}
	//入库日期
	_condition.startDate=DateField.dateToString(beginBillDate.selectedDate, 'YYYY-MM-DD');
	_condition.endDate=DateField.dateToString(endBillDate.selectedDate, 'YYYY-MM-DD');
	_condition.billNo=billNo.selectedItem?billNo.selectedItem.billNo:null;
	_condition.specialSign=specialSign.selected ? "1" : "";
	
	paramQuery.conditions=_condition;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTINATION, function(rev:Object):void
	{
		registerClassAlias("cn.superion.material.entity.MaterialRdsDetail", cn.superion.vo.material.MaterialRdsDetail);
		if (rev.data && rev.data.length > 0)
		{
			for each(var item:Object in rev.data)
			{
				var factoryObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict,'provider',item.factoryCode);
				item.factoryName=factoryObj==null ? "" : factoryObj.providerName;
				
				var deptObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict,'dept',item.wardCode);
				item.wardCode=deptObj ? deptObj.deptName : '';
			}
			var col:ArrayCollection=rev.data as ArrayCollection;
			laryNew = ObjectUtil.copy(col) as ArrayCollection;//byzcl
			var arycol:ArrayCollection=new ArrayCollection(ArrayUtil.copyArray(col.source));
			var patientId:String = null;
			var materialId:String = null;
			//实现汇总的功能都在这个循环里面 byzcl
			for each(var item2:Object in col){
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
					dl2 = item2.amount;
					dl3 = item2.acctAmount;
					dl4 = item2.tradeMoney;
					dl5 = item2.inviteMoney;
					dl6 = item2.retailMoney;
					for each(var item1:Object in col){
						if(item1.patientId != null){
							if(item1.patientId == item2.patientId && item1.materialId == item2.materialId){
								item2.sumMoney += item1.retailMoney;
								item2.wholeSaleMoney += item1.wholeSaleMoney;
								item2.amount += item1.amount;
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
					item2.amount -= dl2;
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
			for(var i:int=0;i<col.length;i++){
				if(col.getItemAt(i).patientId != null && col.getItemAt(i).canelSign =='1'){
					col.removeItemAt(i);
					i=-1;
				}
			}
			gdItems.dataProvider=col;
			gdItemsValue.dataProvider=arycol;
//			toolBar.queryToPreState();
			toolBar.setEnabled(toolBar.btSave, true);
			toolBar.setEnabled(storageCode, false);
			toolBar.setEnabled(deptCode, false);
			toolBar.setEnabled(toolBar.btCancel, true);
			return;
		}
		gdItems.dataProvider=[];
		gdItemsValue.dataProvider=[];
	});
	ro.findReportByCondition(paramQuery);
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
	var lnumHeight:Number=parseFloat(ReportParameter.reportPrintHeight_out)
	lnumHeight=isNaN(lnumHeight)?288*1000:lnumHeight*1000 
	ExternalInterface.call("setPrintPageSize",lnumWidth,lnumHeight)
}


/**
 * 恢复默认打印机的打印页面
 * */
private function setPrintPageToDefault():void{
	ExternalInterface.call("setPrintPageToDefault")
}
