/**
 *		 调价记录单模块
 *		 作者:朱玉峰
 **/
import cn.superion.base.components.controls.TextInputIcon;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.base.util.StringUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialAcct.daily.price.view.WinQueryCondition;
import cn.superion.materialAcct.util.DefaultPage;
import cn.superion.materialAcct.util.MainToolBar;
import cn.superion.materialAcct.util.ReportParameter;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.material.MaterialChangePriceDetail;
import cn.superion.vo.material.MaterialChangePriceMaster;
import cn.superion.vo.material.MaterialRdsAcctMaster;

import com.adobe.utils.DateUtil;
import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

import flash.events.Event;

import flexlib.scheduling.util.DateUtil;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.events.CloseEvent;
import mx.events.ListEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.TextOperationEvent;

public static const MENU_NO:String="0102";
public static const DESTANATION:String="materialAcctChangeImpl";
private var winY:int=0;
private var _materialChangePriceMaster:MaterialChangePriceMaster=new MaterialChangePriceMaster();
//查询主记录ID列表
public var arrayAutoId:Array=new Array();
//当前页，翻页用
public var currentPage:int=0;

/**
 * 初始化当前窗口
 * */
public function doInit():void
{
	initPanel();
	initToolBar();
	//阻止放大镜表格输入内容
	preventDefaultForm();
	parentDocument.title="调价记录单";
	materialCode.width=oldInvitePrice.width;
}


/**
 * 面板初始化
 */
private function initPanel():void
{
	//初始化不可编辑,增加项隐藏
	FormUtils.setFormItemEditable(vg, false);
	hiddenVGroup.visible=false;
	hiddenVGroup.includeInLayout=false;
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.btAdd, toolBar.btModify, toolBar.btDelete, toolBar.btCancel, toolBar.btSave, toolBar.btVerify, toolBar.btAddRow, toolBar.btDelRow, toolBar.btQuery, toolBar.btFirstPage, toolBar.btPrePage, toolBar.btNextPage, toolBar.btLastPage, toolBar.btExit, toolBar.imageList1, toolBar.imageList2, toolBar.imageList3, toolBar.imageList5, toolBar.imageList6]
	var laryEnables:Array=[toolBar.btExit, toolBar.btQuery, toolBar.btAdd]
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 表头设置只读或读写状态
 */
private function setReadOnly(boolean:Boolean):void
{
	FormUtils.setFormItemEditable(vg, boolean);
	hiddenVGroup.visible=boolean;
	hiddenVGroup.includeInLayout=boolean;
}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	materialCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
}

/**
 * 清空表单
 */
public function clearForm(masterFlag:Boolean, detailFlag:Boolean):void
{
	if (masterFlag)
	{
		//清空主记录
		clearMaster();
	}
	if (detailFlag)
	{
		//清空明细
		clearDetail();
	}
}

/**
 * 清空明细
 */
private function clearDetail():void
{
	materialCode.text="";
	newWholeSalePrice.text="";
	newInvitePrice.text="";
	newRetailPrice.text="";
	startDate.selectedDate=new Date();
	detailRemark.text="";
	materialName.text="";
	materialSpec.text="";
	materialUnits.text="";
	oldWholeSalePrice.text="";
	oldInvitePrice.text="";
	oldRetailPrice.text="";
	currentStockAmount.text="";
}

/**
 * 清空主记录
 */
public function clearMaster():void
{
	billNo.text="";
	billDate.selectedDate=new Date();
	changeReason.text="";
	remark.text="";
	salerCode.text="";
	gdItems.dataProvider=null;
	_materialChangePriceMaster=new MaterialChangePriceMaster();
}

/**
 * 回车事件
 **/
private function toNextCtrl(event:KeyboardEvent, fctrlNext:Object):void
{
	FormUtils.toNextControl(event, fctrlNext);
}

/**
 * 备注KeyUp事件
 */
protected function detailRemark_keyUpHandler(event:KeyboardEvent):void
{
	// TODO Auto-generated method stub
	if (event.keyCode == Keyboard.ENTER)
	{
		materialCode.txtContent.setFocus();
		materialCode.text="";
	}
}

/**
 * 物资编码KeyUp事件
 */
protected function materialCode_keyUpHandler(event:KeyboardEvent):void
{
	if (event.keyCode != Keyboard.ENTER)
	{
		return;
	}
	materialCode_queryIconClickHandler(event);
	return;
	newWholeSalePrice.setFocus();
}

/**
 * 供应商字典
 */ 
protected function salerCode_queryIconClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showProviderDict(function(rev:Object):void
	{
		event.target.text=rev.providerName;
		_materialChangePriceMaster.salerCode=rev.providerId;
		_materialChangePriceMaster.salerName=rev.providerName;
	}, x, y);
}

/**
 * 物资字典
 */
protected function materialCode_queryIconClickHandler(event:Event):void
{
	//打开物资字典
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 338;
	var lstorageCode:String='';
	lstorageCode=null;
	DictWinShower.showMaterialDictNew(lstorageCode, '', '', false, function(faryItems:Array):void
	{
		fillIntoGrid(faryItems);
	}, x, y);
}

/**
 * 自动完成表格回调
 * */
private function fillIntoGrid(fItem:Array):void
{
	var laryDetails:ArrayCollection=gdItems.dataProvider as ArrayCollection;
		var materialChangePriceDetail:MaterialChangePriceDetail=new MaterialChangePriceDetail();
		//放大镜取出的值、赋值
		materialChangePriceDetail=fillDetailForm(fItem[0]);
		if(fItem[0].produceCorporationName==null||fItem[0].produceCorporationName=="")
		{
			materialChangePriceDetail.factoryCode="";
		}
		laryDetails.addItem(materialChangePriceDetail);
	gdItems.dataProvider=laryDetails;
	gdItems.selectedIndex=laryDetails.length - 1;
	findCurrentStockByIdStorage();
	newWholeSalePrice.setFocus();
}

/**
 * 明细表单赋值  
 */
private function fillDetailForm(faryItems:Object):MaterialChangePriceDetail
{
	var materialChangePriceDetail:MaterialChangePriceDetail=new MaterialChangePriceDetail();
	var ro:RemoteObject=RemoteUtil.getRemoteObject("commMaterialServiceImpl", function(rev:Object):void
	{
		materialChangePriceDetail.amount=rev.data[0].totalCurrentStockAmount;
	});
	ro.findCurrentStockByIdStorage(faryItems.materialId, 0);
	//物资名称文本赋值
	materialCode.text=faryItems.materialCode;
	//物资id
	materialChangePriceDetail.materialId=faryItems.materialId;
	//物资编码
	materialChangePriceDetail.materialCode=faryItems.materialCode;
	//物资分类
	materialChangePriceDetail.materialClass=faryItems.materialClass;
	//物资名称
	materialChangePriceDetail.materialName=faryItems.materialName;
	//规格型号 
	materialChangePriceDetail.materialSpec=faryItems.materialSpec;
	//单位
	materialChangePriceDetail.materialUnits=faryItems.materialUnits;
	//原批发价
	materialChangePriceDetail.oldWholeSalePrice=faryItems.wholeSalePrice;
	//现批发价
	materialChangePriceDetail.newWholeSalePrice=faryItems.wholeSalePrice;
	//原中标价
	materialChangePriceDetail.oldInvitePrice=faryItems.invitePrice;
	//现中标价
	materialChangePriceDetail.newInvitePrice=faryItems.invitePrice;
	//原售价
	materialChangePriceDetail.oldRetailPrice=faryItems.retailPrice;
	//现售价
	materialChangePriceDetail.newRetailPrice=faryItems.retailPrice;
	//生产厂家
	materialChangePriceDetail.factoryCode=faryItems.factoryCode;
	//执行日期
	materialChangePriceDetail.startDate=startDate.selectedDate;
	materialChangePriceDetail.oldTradePrice=faryItems.tradePrice;
	materialChangePriceDetail.serialNo=0;
	materialChangePriceDetail.newTradePrice=faryItems.tradePrice;
	oldWholeSalePrice.text=faryItems.wholeSalePrice;
	oldInvitePrice.text=faryItems.invitePrice;
	oldRetailPrice.text=faryItems.retailPrice;
	materialName.text=faryItems.materialName;
	materialSpec.text=faryItems.materialSpec;
	materialUnits.text=faryItems.materialUnits;
	var timer:Timer=new Timer(100, 1)
	timer.addEventListener(TimerEvent.TIMER, function(e:Event):void
	{
		newWholeSalePrice.setFocus();
	})
	timer.start();
	return materialChangePriceDetail;
}

/**
 * 现批发价change事件
 */
protected function newWholeSalePrice_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub
	if (gdItems.selectedItem)
	{
		gdItems.selectedItem.newWholeSalePrice=Number(newWholeSalePrice.text);
		gdItems.selectedItem.newTradePrice=Number(newWholeSalePrice.text); //默认将现进价 = 现批发价
	}
}

/**
 * 有效日期change事件
 */
protected function availDate_changeHandler(event:Event):void
{
	var lRdsDetail:MaterialChangePriceDetail=gdItems.selectedItem as MaterialChangePriceDetail;
	if (!lRdsDetail)
	{
		return;
	}
	gdItems.selectedItem.startDate=startDate.selectedDate;
}

/**
 * 现中标价change事件
 */
protected function newInvitePrice_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub
	if (gdItems.selectedItem)
	{
		gdItems.selectedItem.newInvitePrice=Number(newInvitePrice.text);
	}
}

/**
 * 现售价change事件
 */
protected function newRetailPrice_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub
	if (gdItems.selectedItem)
	{
		gdItems.selectedItem.newRetailPrice=Number(newRetailPrice.text);
	}
}

/**
 * 备注Change事件
 */
protected function detailRemark_changeHandler(event:TextOperationEvent):void
{
	// TODO Auto-generated method stub
	if (gdItems.selectedItem)
	{
		gdItems.selectedItem.detailRemark=detailRemark.text;
	}
}

/**
 * 填充当前表单
 */
protected function gdItems_itemClickHandler(event:ListEvent):void
{
	// TODO Auto-generated method stub
	FormUtils.fillFormByItem(hiddenVGroup, gdItems.selectedItem);
	findCurrentStockByIdStorage();
}

public function findCurrentStockByIdStorage():void
{
	var ro:RemoteObject=RemoteUtil.getRemoteObject("commMaterialServiceImpl", function(rev:Object):void
	{
		currentStockAmount.text=rev.data[0].totalCurrentStockAmount;
	});
	ro.findCurrentStockByIdStorage(gdItems.selectedItem.materialId, 0);
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
	var excelTitle:String='调价单'+_currentDate;
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
	setPrintPageSize();
	var dataList:ArrayCollection=gdItems.dataProvider as ArrayCollection;
	var rawData:ArrayCollection = gdItems.getRawDataProvider() as ArrayCollection;
	var lastItem:Object=rawData.getItemAt(rawData.length - 1);
	preparePrintData(dataList);
	var dict:Dictionary=new Dictionary();
	dict["主标题"]="调价记录单";
	dict["调价单位"]=salerCode.text;
	dict["调价单号"]=_materialChangePriceMaster.billNo;
	dict["调价日期"]=_materialChangePriceMaster.billDate;
	dict["审核"]=shiftTo(_materialChangePriceMaster.verifier)
	dict["制单"]=shiftTo(_materialChangePriceMaster.maker);
	dict["表尾第一行"]=createPrintSecondBottomLine(lastItem);
	if (printSign == "1")
	{
		ReportPrinter.LoadAndPrint("report/materialAcct/daily/price/ChangePrice.xml", dataList, dict);
	}
	else
	{
		ReportViewer.Instance.Show("report/materialAcct/daily/price/ChangePrice.xml", dataList, dict);
	}
}
/**
 * 生成表格尾第一行
 * */
private function createPrintSecondBottomLine(fLastItem:Object):String
{
	var lstrLine:String="审核：{0}                                                                                                  制单：{1}";
	var makerv:String=shiftTo(_materialChangePriceMaster.maker);
	var verifierv:String=shiftTo(_materialChangePriceMaster.verifier)
	lstrLine=StringUtils.format(lstrLine, 
		verifierv,
		makerv)
	return lstrLine;
}
/**
 * 增加
 */
protected function addClickHandler(event:Event):void
{
	//新增权限
	if (!checkUserRole('01'))
	{
		return;
	}
	//增加按钮
	toolBar.addToPreState()
	//设置可写
	setReadOnly(true);
	//清空当前表单
	clearForm(true, true);
	changeReason.setFocus();
}

/**
 * 修改
 */ 
protected function modifyClickHandler(event:Event):void
{
	//设置可写
	setReadOnly(true);
	toolBar.modifyToPreState();
	billDate.setFocus();
}


/**
 * 删除
 */
protected function deleteClickHandler(event:Event):void
{
	//删除权限
	if (!checkUserRole('03'))
	{
		return;
	}
	Alert.show("您确定要删除当前记录？", "提示信息", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
	{
		if (e.detail == Alert.YES)
		{
			var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
			{
				Alert.show("删除调价记录单成功！", "提示信息");
				//清空当前表单
				clearForm(true, true);
				doInit();
			});
			ro.del(_materialChangePriceMaster.autoId);
		}
	});
}


/**
 * 保存
 */
protected function saveClickHandler(event:Event):void
{
	//保存权限
	if (!checkUserRole('04'))
	{
		return;
	}
	if(gdItems.dataProvider.length  == 0 ){
		return;
	}
	//
	var exitFlag:Boolean = false;
	for each(var item : Object in gdItems.dataProvider){
		var ss:int = cn.superion.base.util.DateUtil.getTimeSpans(item.startDate,new Date(),'day');
		if( ss > 0 ){
			exitFlag = true;
			break;
		}
	}
	//
	if(exitFlag){
		Alert.show('执行日期必须在今天之后','提示');
		return;	
	}
	if(_materialChangePriceMaster.salerCode==null||_materialChangePriceMaster.salerCode=="")
	{
		Alert.show("供应商不能空!","提示",Alert.YES,null, function(e:CloseEvent):void{
			if (e.detail == Alert.YES)
			{
				salerCode.txtContent.setFocus();
				return;
			}
		} );
		return;
	}
	fillRdsMaster();
	toolBar.btSave.enabled=false;
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		findRdsById(rev.data[0].autoId);
		//设置可写
		toolBar.saveToPreState();
		setReadOnly(false);
		Alert.show("保存成功", "提示");
	});
	ro.save(_materialChangePriceMaster, gdItems.dataProvider);
}

/**
 * 给主记录赋值
 */
private function fillRdsMaster():void
{
	_materialChangePriceMaster.billNo=billNo.text;
	_materialChangePriceMaster.billDate=billDate.selectedDate;
	_materialChangePriceMaster.changeReason=changeReason.text;
	_materialChangePriceMaster.remark=remark.text;
}

/**
 * 更具数据状态显示不同的按钮
 */
protected function stateButton(currentStatus:String):void
{
	var state:Boolean=(currentStatus == "1" ? false : true);
	toolBar.btModify.enabled=state;
	toolBar.btDelete.enabled=state;
	toolBar.btVerify.enabled=state;
	toolBar.btPrint.enabled=true;
	toolBar.btExp.enabled=true;
}

/**
 * 保存前验证主记录
 */
private function validateMaster():Boolean
{
	return true;
}

/**
 * 放弃
 */
protected function cancelClickHandler(event:Event):void
{
	Alert.show("您是否放弃当前操作吗？", "提示", Alert.YES | Alert.NO, null, function(e:CloseEvent):void
	{
		if (e.detail == Alert.NO)
		{
			return;
		}
		//清空当前表单
		clearForm(true, true);
		doInit();
	})
}

/**
 * 审核
 */
protected function verifyClickHandler(event:Event):void
{
	//审核权限
	if (!checkUserRole('06'))
	{
		return;
	}
	if (_materialChangePriceMaster.currentStatus == "1")
	{
		Alert.show('调价记录单已经审核', '提示信息');
		return;
	}
	var exitFlag:Boolean = false;
	for each(var item : Object in gdItems.dataProvider){
		var ss:int = cn.superion.base.util.DateUtil.getTimeSpans(item.startDate,new Date(),'day');
		if( ss > 0 ){
			exitFlag = true;
			break;
		}
	}
	//
	if(exitFlag){
		Alert.show('执行日期必须在今天之后','提示');
		return;	
	}
	Alert.show('您是否审核当前调价记录单？', '提示信息', Alert.YES | Alert.NO, null, function(e:*):void
	{
		if (e.detail == Alert.YES)
		{
			var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
			{
				Alert.show("调价记录单审核成功！", "提示信息");
				toolBar.verifyToPreState();
				findRdsById(_materialChangePriceMaster.autoId);
			});
			ro.verify(_materialChangePriceMaster.autoId);
		}
	})
}

/**
 * 增行
 */
protected function addRowClickHandler(event:Event):void
{
	materialCode_queryIconClickHandler(event)
}

/**
 * 删行
 */
protected function delRowClickHandler(event:Event):void
{
	//光标所在位置
	var laryDetails:ArrayCollection=gdItems.dataProvider as ArrayCollection;
	var i:int=laryDetails.getItemIndex(gdItems.selectedItem);
	if (i < 0)
	{
		return
	}
	//清空当前表单
	clearForm(false, true);
	laryDetails.removeItemAt(i);
	gdItems.dataProvider=laryDetails;
	gdItems.invalidateList();
	gdItems.selectedIndex=gdItems.dataProvider.length - 1;
	gdItems.selectedIndex=i == 0 ? 0 : (i - 1);
	EvaluateList(gdItems.selectedItem as MaterialChangePriceDetail);
	if(gdItems.selectedItem)
	{
		findCurrentStockByIdStorage();
	}
}

/**
 * 明细表格赋值
 */
private function EvaluateList(mcpd:MaterialChangePriceDetail):void
{
	FormUtils.fillFormByItem(detailGroup, mcpd);
}

/**
 * 查询
 */
protected function queryClickHandler(event:Event):void
{
	var queryWin:WinQueryCondition=PopUpManager.createPopUp(this, WinQueryCondition, true) as WinQueryCondition;
	queryWin.data={parentWin: this};
	PopUpManager.centerPopUp(queryWin);
}

/**
 * 首页
 */
protected function firstPageClickHandler(event:Event):void
{
	//定位到数组第一个
	if (arrayAutoId.length < 1)
	{
		return;
	}
	currentPage=0;
	var strAutoId:String=arrayAutoId[currentPage] as String;
	findRdsById(strAutoId);
	
	toolBar.firstPageToPreState()
}

/**
 * 下一页
 */
protected function nextPageClickHandler(event:Event):void
{
	if (arrayAutoId.length < 1)
	{
		return;
	}
	currentPage++;
	if (currentPage >= arrayAutoId.length)
	{
		currentPage=arrayAutoId.length - 1;
	}
	
	var strAutoId:String=arrayAutoId[currentPage] as String;
	findRdsById(strAutoId);
	
	toolBar.nextPageToPreState(currentPage, arrayAutoId.length - 1);
}

/**
 * 上一页
 */
protected function prePageClickHandler(event:Event):void
{
	if (arrayAutoId.length < 1)
	{
		return;
	}
	currentPage--;
	if (currentPage <= 0)
	{
		currentPage=0;
	}
	
	var strAutoId:String=arrayAutoId[currentPage] as String;
	findRdsById(strAutoId);
	
	toolBar.prePageToPreState(currentPage);
}

/**
 * 末页
 */
protected function lastPageClickHandler(event:Event):void
{
	if (arrayAutoId.length < 1)
	{
		return;
	}
	currentPage=arrayAutoId.length - 1;
	
	var strAutoId:String=arrayAutoId[currentPage] as String;
	findRdsById(strAutoId);
	
	toolBar.lastPageToPreState();
}

/**
 * 翻页调用此函数
 * */
public function findRdsById(fstrAutoId:String):void
{
	var ro:RemoteObject=RemoteUtil.getRemoteObject(DESTANATION, function(rev:Object):void
	{
		if (rev.data && rev.data.length > 0 && rev.data[0] != null && rev.data[1] != null)
		{
			_materialChangePriceMaster=rev.data[0];
			_materialChangePriceMaster.maker=shiftTo(_materialChangePriceMaster.maker);
			_materialChangePriceMaster.verifier=shiftTo(_materialChangePriceMaster.verifier);
			gdItems.dataProvider=rev.data[1];
			stateButton(rev.data[0].currentStatus);
			fillMaster(_materialChangePriceMaster);
		}
		else
		{
			//清空当前表单
			clearForm(true, true);
			doInit();
		}
	});
	ro.findByAutoId(fstrAutoId);
}
/**
 * 填充表头部分
 */
private function fillMaster(mcpm:MaterialChangePriceMaster):void
{
	if (!mcpm)
	{
		return;
	}
	FormUtils.fillFormByItem(this, mcpm);
	FormUtils.fillTextByDict(salerCode,mcpm.salerCode,"provider");
}

/**
 * 批号
 */
private function batchLBF(item:Object, column:DataGridColumn):String
{
	if (item.batch == '0')
	{
		item.batchName='';
	}
	else
	{
		item.batchName=item.batch;
	}
	return item.batchName;
}

/**
 * 退出
 */
protected function exitClickHandler(event:Event):void
{
	PopUpManager.removePopUp(this.parentDocument as IFlexDisplayObject);
	DefaultPage.gotoDefaultPage();
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
// 制单人
protected function shiftTo(name:String):String
{
	var makerItem:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict, 'personId', name);
	var maker:String=makerItem == null ? "" : makerItem.personIdName;
	return maker;
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
		item.SalePrices=(Number(item.newWholeSalePrice)-Number(item.oldWholeSalePrice))*Number(item.amount);
		return item.SalePrices;
	}
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

