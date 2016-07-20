/**
 *		 入库报告单列表查询条件窗体
 *		 author:周作建   2011.05.22
 *       modify:吴小娟  2011.06.10
 *		 checked by：
 **/

import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialAcct.stat.receiveList.ModReceiveList;
import cn.superion.materialAcct.util.MainToolBar;

import flash.profiler.showRedrawRegions;
import flash.sampler.isGetterSetter;

import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

public var iparentWin:ModReceiveList;
private var _winY:int = 0;
//条件对象
private  var _condition:Object={};//这里可以定义为static，如果是module则不可以

/**
 * 初始化当前窗口
 * */
protected function doInit():void
{
	_winY=this.parentApplication.screen.height - 345;
	//授权仓库赋值
	if (AppInfo.currentUserInfo.storageList != null && AppInfo.currentUserInfo.storageList.length > 0)
	{
		storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
		storageCode.selectedIndex=0;
	}
	isGive.textInput.editable=false;
}

/**
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e, fcontrolNext);
}

/**
 * 供应单位字典
 */
protected function salerCode_queryIconClickHandler(event:Event):void
{
	DictWinShower.showProviderDict(function(rev:Object):void
	{
		salerCode.txtContent.text = rev.providerName;	
		_condition['salerCode'] = rev.providerId;	
	}, 0, _winY);
}

/**
 * 人员档案字典
 */
protected function accounter_queryIconClickHandler(event:Event):void
{
	DictWinShower.showPersonDict(function(rev:Object):void
	{
		accounter.txtContent.text = rev.name;
		_condition['accounter'] = rev.personId;
	}, 0, _winY);
}

/**
 * 确定回车事件处理方法
 * */
protected function btConfirm_keyUpHandler(event:KeyboardEvent):void
{
	if (event.keyCode == Keyboard.ENTER)
	{
		btConfirm_clickHandler();
	}
}

/**
 * 确定查询事件处理方法
 * */
protected function btConfirm_clickHandler():void
{
	var paramQuery:ParameterObject=new ParameterObject();
	//仓库
	if (storageCode.selectedItem != null && storageCode.selectedIndex > -1)
	{
		_condition['storageCode']=storageCode.selectedItem.storageCode;
	}
	//出入库号
	_condition['beginRdBillNo']=beginRdBillNo.text == ""?endRdBillNo.text:beginRdBillNo.text;
	_condition['endRdBillNo']=endRdBillNo.text == ""?beginRdBillNo.text:endRdBillNo.text;
	//发票日期
	if (chkInvoiceDate.selected)
	{
		//开始发票日期
		_condition['beginInvoiceDate']=beginInvoiceDate.selectedDate;
		//结束发票日期
		_condition['endInvoiceDate']=MainToolBar.addOneDay(endInvoiceDate.selectedDate);
	}
	else
	{
		_condition['beginInvoiceDate']=null;
		_condition['endInvoiceDate']=null;
	}
	//单据起始日期
	if (chkBillDate1.selected)
	{
		//开始单据起始日期
		_condition['beginBillDate1']=beginBillDate1.selectedDate;
		_condition['endBillDate1']=MainToolBar.addOneDay(endBillDate1.selectedDate);
	}
	else
	{
		_condition['beginBillDate1']=null;
		_condition['endBillDate1']=null;
	}
	//单据终止日期
	if (chkBillDate2.selected)
	{
		//开始单据终止日期
		_condition['beginBillDate2']=beginBillDate2.selectedDate;
		_condition['endBillDate2']=MainToolBar.addOneDay(endBillDate2.selectedDate);
	}
	else
	{
		_condition['beginBillDate2']=null;
		_condition['endBillDate2']=null;
	}
	//核算日期
	if (chkAccountDate.selected)
	{
		//开始核算日期
		_condition['beginAccountDate']=beginAccountDate.selectedDate;
		//结束核算日期
		_condition['endAccountDate']=MainToolBar.addOneDay(endAccountDate.selectedDate);
	}
	else
	{
		_condition['beginAccountDate']=null;
		_condition['endAccountDate']=null;
	}
	_condition['isGive']=isGive.selectedItem ? isGive.selectedItem.giveCode : "";
	iparentWin._isGive=_condition['isGive'];
	
	paramQuery.conditions=_condition;
	//关闭查询框
	PopUpManager.removePopUp(this);
	
	
	iparentWin.toolBar.btPrint.enabled=true;
	iparentWin.toolBar.btExp.enabled=true;
	iparentWin.dgMasterList.reQuery(paramQuery);
}

/**
 * 取消按钮事件响应方法
 * */
protected function closeWin():void
{
	PopUpManager.removePopUp(this);
}

/**
 * 取消
 */
protected function btReturn_clickHandler(event:MouseEvent):void
{
	PopUpManager.removePopUp(this);
}