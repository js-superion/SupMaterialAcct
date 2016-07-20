/**
 *		 入库报告单列表查询条件窗体
 *		 author:周作建   2011.05.22
 *		 checked by：
 **/

import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialAcct.stat.receiveStat.ModReceiveStat;
import cn.superion.materialAcct.util.MainToolBar;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

public var iparentWin:Object;
private var _winY:int = 0;
private var _conditions:Object = {};
//
private var _statFlag:String = null;
private var _salerCode:String = null;
private var _beginMaterialClass:String = null;
private var _endMaterialClass:String = null;
private var _materialName:String = null;
private var _maker:String = null;
private var _accounter:String = null;

/**
 * 初始化
 * */
private function doInit():void{
	//授权仓库赋值
	if (AppInfo.currentUserInfo.storageList != null && AppInfo.currentUserInfo.storageList.length > 0)
	{
		storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
		storageCode.selectedIndex=0;
	}
	_winY=this.parentApplication.screen.height - 345;
	cbxIsGive.textInput.editable=false;
	//
//	chkSale.selected =iparentWin.myViewStack.selectedChild == iparentWin.saleGroup?true:false;
//	chkMaterialCode.selected =iparentWin.myViewStack.selectedChild == iparentWin.saleMaterialGroup?true:false;
}

/**
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e, fcontrolNext);
}

/**
 * 供应字典
 */
protected function salerCode_queryIconClickHandler(event:Event):void
{
	DictWinShower.showProviderDict(function(rev:Object):void
	{
		salerCode.text = rev.providerName;	
		_salerCode = rev.providerId;	
	}, 0, _winY);
}
/**
 * 物资分类字典
 */
protected function materialClass_queryIconClickHandler(flag:String):void
{
	DictWinShower.showMaterialClassDict(function(rev:Object):void
	{
		if(flag =='1'){
			beginMaterialClass.text = rev.classCode;	
			_beginMaterialClass = rev.classCode;	
		}
		if(flag =='2'){
			endMaterialClass.text = rev.classCode;	
			_endMaterialClass = rev.classCode;	
		}
	}, 0, _winY);
}

/**
 * 物资字典
 */
protected function materialName_queryIconClickHandler(event:Event):void
{
	var lstorageCode:String='';
	lstorageCode=(storageCode.selectedItem || {}).storageCode;
	
	DictWinShower.showMaterialDictNew(lstorageCode, '', '', true, function(faryItems:Array):void
	{
		materialName.text = faryItems[0].materialName;	
		_materialName = faryItems[0].materialCode;	
	}, 0, _winY);
}
/**
 * 人员字典
 * */
protected function personId_queryIconClickHandler(flag:String):void
{
	DictWinShower.showPersonDict(function(rev:Object):void
	{
		if(flag =='1'){
			maker.text = rev.personIdName;	
			_maker = rev.personId;
		}
		if(flag =='2'){
			verifier.text = rev.personIdName;	
			_accounter = rev.personId;
		}
	}, 0, _winY);
}
/**
 * 取消按钮事件响应方法
 * */
protected function closeWin():void
{
	PopUpManager.removePopUp(this);
}

/**
 * 确认
 */
protected function btConfirm_clickHandler(event:MouseEvent):void
{
	if (chkSale.selected && chkMaterialCode.selected)
	{
		iparentWin.myViewStack.selectedChild=iparentWin.saleMaterialGroup;
		_statFlag = "3";
	}
	else if (chkSale.selected && !chkMaterialCode.selected) //按照供应单位分组，不加发票号、发票日期等；
	{
		iparentWin.myViewStack.selectedChild=iparentWin.saleGroup;
		_statFlag = "1";
	}
	else if(!chkSale.selected && chkMaterialCode.selected) //按照物资编码分组，不加发票号、发票日期等；
	{
		iparentWin.myViewStack.selectedChild=iparentWin.materialGroup1;
		_statFlag = "2";
	}
	else if (!chkSale.selected && !chkMaterialCode.selected) //按照物资编码分组，加发票号、发票日期等；
	{
		iparentWin.myViewStack.selectedChild=iparentWin.materialGroup;
		_statFlag = "4";
	}
	var para:ParameterObject = new ParameterObject();
	_conditions = {
			"statFlag":_statFlag == null ?"1":_statFlag,
			"salerCode":_salerCode == null ?null:_salerCode,
			"beginMaterialClass":_beginMaterialClass == null ?null:_beginMaterialClass,
			"endMaterialClass":_endMaterialClass == null ?null:_endMaterialClass,
			"materialCode":_materialName == null ?null:_materialName,
			"maker":_maker == null ?null:_maker,
			"accounter":_accounter == null ?null:_accounter,
			
			"storageCode":storageCode.selectedItem?storageCode.selectedItem.storageCode:"",
			"beginRdBillNo":beginRdBillNo.text == ""?endRdBillNo.text:beginRdBillNo.text,
			"endRdBillNo":endRdBillNo.text == ""?beginRdBillNo.text:endRdBillNo.text,
			"beginInvoiceDate":chkInvoiceDate.selected?beginInvoiceDate.selectedDate:null,
			"endInvoiceDate":chkInvoiceDate.selected?MainToolBar.addOneDay(endInvoiceDate.selectedDate):null,
			"beginMaterialCode":(beginMaterialCode.text == '' && endMaterialCode.text !='')?endMaterialCode.text:beginMaterialCode.text,
			"endMaterialCode":(endMaterialCode.text == '' && beginMaterialCode.text !='')?beginMaterialCode.text:endMaterialCode.text,
			"materialName":materialName.text,
			"beginMakeDate":chkMakeDate.selected?beginMakeDate.selectedDate : null,
			"endMakeDate":chkMakeDate.selected?MainToolBar.addOneDay(endMakeDate.selectedDate):null,
			"beginAccountDate":chkVerifyDate.selected?beginVerifyDate.selectedDate : null,
			"endAccountDate":chkVerifyDate.selected?MainToolBar.addOneDay(endVerifyDate.selectedDate):null,
			"isGive":cbxIsGive.selectedItem.giveCode
	};
	para.conditions = _conditions;
	var ro:RemoteObject = RemoteUtil.getRemoteObject(ModReceiveStat.DESTANATION,function (rev:Object):void{
		if(rev.data.length == 0) {
//			iparentWin._dataProvider.removeAll();
			if(_statFlag=="1")
			{
				iparentWin.gdSaleGroup.dataProvider=new ArrayCollection();
			}
			else if(_statFlag=="2")
			{
				iparentWin.gdMasterialGroup1.dataProvider=new ArrayCollection();
			}
			else if(_statFlag=="3")
			{
				iparentWin.gdSaleMaterialGroup.dataProvider=new ArrayCollection();
			}
			else if(_statFlag=="4")
			{
				iparentWin.gdMaterialGroup.dataProvider=new ArrayCollection();
			}
			iparentWin.tbarMain.btExp.enabled = false;
			iparentWin.tbarMain.btPrint.enabled = false;
			return;
		}
		btReturn_clickHandler(null);
		iparentWin._dataProvider.removeAll();
		if(_statFlag=="1")
		{
			iparentWin.gdSaleGroup.dataProvider=rev.data[0];
			iparentWin.gdSaleGroup.sortableColumns="true"
		}
		else if(_statFlag=="2")
		{
			iparentWin.gdMasterialGroup1.dataProvider=rev.data[0];
			iparentWin.gdMasterialGroup1.sortableColumns="true"
		}
		else if(_statFlag=="3")
		{
			iparentWin.gdSaleMaterialGroup.dataProvider=rev.data[0];
			iparentWin.gdSaleMaterialGroup.sortableColumns="true"
		}
		else if(_statFlag=="4")
		{
			iparentWin.gdMasterialGroup.dataProvider=rev.data[0];
			iparentWin.gdMasterialGroup.sortableColumns="true"
		}
		iparentWin.tbarMain.btExp.enabled = true;
		iparentWin.tbarMain.btPrint.enabled = true;
		iparentWin.salerName.text = salerCode.text;
		//最大入库单
		iparentWin.max=rev.data[1][0][0];
		iparentWin.mit=rev.data[1][0][1];
		fillValueToReport();
	});
	ro.findReceiveStatListByCondition(para);
}

/**
 * 将弹出框的值给将要打印的报表
 * */
private function fillValueToReport():void{
	iparentWin._statFlag = _statFlag; 
	//将弹出页面的部分值赋予主页面
	iparentWin._storageName = storageCode.textInput.text;
	//
	iparentWin._billDate = 
		"从："+(chkMakeDate.selected?DateUtil.dateToString(beginMakeDate.selectedDate,'YYYY-MM-DD'):"") 
		+ "到："
		+(chkMakeDate.selected?DateUtil.dateToString(endMakeDate.selectedDate,'YYYY-MM-DD'):"");
	//
	iparentWin._accountDate = 
		"从："+(chkVerifyDate.selected?DateUtil.dateToString(beginVerifyDate.selectedDate,'YYYY-MM-DD'):"")
		+ "到："
		+(chkVerifyDate.selected?DateUtil.dateToString(endVerifyDate.selectedDate,'YYYY-MM-DD'):"");
}
/**
 * 返回
 */
protected function btReturn_clickHandler(event:MouseEvent):void
{
	PopUpManager.removePopUp(this);
}