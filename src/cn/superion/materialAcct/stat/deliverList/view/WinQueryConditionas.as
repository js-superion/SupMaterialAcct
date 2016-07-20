/**
 *		 入库报告单列表查询条件窗体
 *		 author:周作建   2011.05.22
 *		 checked by：
 **/

import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialAcct.util.MaterialDictShower;
import cn.superion.materialAcct.stat.deliverList.ModDeliverList;
import cn.superion.materialAcct.util.MainToolBar;
import cn.superion.materialAcct.util.MaterialDictShower;

import com.adobe.utils.StringUtil;

import mx.events.FlexEvent;
import mx.managers.PopUpManager;

public var iparentWin:ModDeliverList;
private var _winY:int=0;
//条件对象
private static var _condition:Object={}; //这里可以定义为static，如果是module则不可以

/**
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e, fcontrolNext);
}

/**
 * 取消按钮事件响应方法
 * */
protected function closeWin():void
{
	PopUpManager.removePopUp(this);
}

/**
 * 初始化
 */
protected function doInit():void
{
	// TODO Auto-generated method stub
	_condition={};
	_winY=this.parentApplication.screen.height - 345;
	//授权仓库赋值
	if (AppInfo.currentUserInfo.storageList != null && AppInfo.currentUserInfo.storageList.length > 0)
	{
		storageCode.dataProvider=AppInfo.currentUserInfo.storageList;
		storageCode.selectedIndex=0;
	}
	unitsCode.dataProvider = MaterialDictShower.SYS_UNITS;//加载泰州南北院的信息
//	unitsCode.requireSelection = true;
}

/**
 * 部门档案
 */
protected function saleCode_queryIconClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	MaterialDictShower.showDeptDict(function(rev:Object):void
		{
			saleCode.txtContent.text=rev.deptName;
			iparentWin.deptName = rev.deptName;
			_condition['deptCode']=rev.deptCode;
		}, 0, _winY);
}

/**
 * 记账人
 */
protected function verifier_queryIconClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	DictWinShower.showPersonDict(function(rev:Object):void
		{
			verifier.txtContent.text=rev.name;
			_condition['accounter']=rev.personId;
		}, 0, _winY);
}

/**
 * 确定查询事件处理方法
 */
protected function btConfirm_clickHandler(event:MouseEvent):void
{
	// TODO Auto-generated method stub
	var paramQuery:ParameterObject=new ParameterObject();
	var ldateEndInvoiceDate:Date=new Date();
	//仓库
	if (storageCode.selectedItem != null && storageCode.selectedIndex > -1)
	{
		_condition['storageCode']=storageCode.selectedItem.storageCode;
		iparentWin.storageName = storageCode.selectedItem.storageName;//仓库赋给父页面
	}
	//出库日期
	if (chkBillDate.selected)
	{
		//开始出库日期
		_condition['beginBillDate1']=beginBillDate.selectedDate;
		iparentWin.beginBillDate = beginBillDate.selectedDate;//仓库赋给父页面
		//结束出库日期
		_condition['endBillDate1']=MainToolBar.addOneDay(endBillDate.selectedDate);;
		iparentWin.endBillDate = _condition['endBillDate1'];
	}
	else
	{
		_condition['beginBillDate1']=null;
		_condition['endBillDate1']=null;
	}
	//制单日期
	if (chkMakeDate.selected)
	{
		//开始制单日期
		_condition['beginBillDate2']=beginMakeDate.selectedDate;
		_condition['endBillDate2']=MainToolBar.addOneDay(endMakeDate.selectedDate);
	}
	else
	{
		_condition['beginBillDate2']=null;
		_condition['endBillDate2']=null;
	}
	//核算日期
	if (chkVerifyDate.selected)
	{
		//开始核算日期
		_condition['beginAccountDate']=beginVerifyDate.selectedDate;
		_condition['endAccountDate']=MainToolBar.addOneDay(endVerifyDate.selectedDate);;
	}
	else
	{
		_condition['beginAccountDate']=null;
		_condition['endAccountDate']=null;
	}
	//出入库号
	_condition['beginRdBillNo']=beginRdBillNo.text == ""?endRdBillNo.text:beginRdBillNo.text;
	_condition['endRdBillNo']=endRdBillNo.text == ""?beginRdBillNo.text:endRdBillNo.text;
	_condition['deptUnitsCode']=StringUtil.trim(unitsCode.textInput.text).length == 0 ? null:unitsCode.selectedItem.unitsCode;
	paramQuery.conditions=_condition;
	//关闭查询框
	PopUpManager.removePopUp(this);
	
	iparentWin.dgMasterList.reQuery(paramQuery);
	iparentWin.tbarMain.btPrint.enabled=false;
	iparentWin.	tbarMain.btExp.enabled=false;	
}