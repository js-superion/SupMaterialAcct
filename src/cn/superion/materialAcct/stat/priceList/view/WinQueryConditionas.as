/**
 *		 入库报告单列表查询条件窗体
 *		 author:周作建   2011.05.22
 *		 checked by：
 **/

import cn.superion.base.util.FormUtils;

import mx.managers.PopUpManager;

import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;

import mx.controls.Alert;
import mx.rpc.remoting.RemoteObject;
private var fparameter:Object={};
public var iparentWin:Object={};
protected function btConfirm_clickHandler(event:MouseEvent):void
{
	// TODO Auto-generated method stubendMaterialNo
	fparameter["beginBillNo"]=beginBillNo.text==""?null:beginBillNo.text;
	fparameter["endBillNo"]=endBillNo.text==""?null:endBillNo.text;
	fparameter["beginBillDate"]=chkBillDate.selected ? beginBillDate.text:null;
	fparameter["endBillDate"]=chkBillDate.selected?endBillDate.text:null;;
	fparameter["beginMakeDate"]=chkMakeDate.selected?beginMakeDate.text:null;
	fparameter["endMakeDate"]=chkMakeDate.selected?endMakeDate.text:null;
	fparameter["beginMaterialCode"]=beginMaterialCode.text==""?null:beginMaterialCode.text;
	fparameter["endMaterialCode"]=endMaterialNo.text==""?null:beginMaterialCode.text;
	var paramsQuery:ParameterObject=new ParameterObject();
	paramsQuery.conditions=fparameter;
	iparentWin.dgMasterList.reQuery(paramsQuery);
	PopUpManager.removePopUp(this);
}
/**
 * 开始物资分类
 */ 
protected function beginMaterialClass_queryIconClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialClassDict(function(rev:Object):void
	{
		event.target.text=rev.className;
		fparameter["beginMaterialClass"]=rev.classCode;
	}, 0, y);
}
/**
 * 结束物资分类
 */ 
protected function endMaterialClass_queryIconClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialClassDict(function(rev:Object):void
	{
		event.target.text=rev.className;
		fparameter["endMaterialClass"]=rev.classCode;
	}, 0, y);
}
/**
 * 物资名称
 */ 
protected function materialName_queryIconClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	var lstorageCode:String='';
	lstorageCode=null;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialDictNew(lstorageCode, '', '', true, function(faryItems:Object):void
	{
		event.target.text=faryItems.materialName;
		fparameter["materialName"]=faryItems.materialCode;
	}, 0, y);
}
/**
 *  制单人
 */ 
protected function maker_queryIconClickHandler(event:Event):void
{
	// TODO Auto-generated method stub
	// TODO Auto-generated method stub
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showPersonDict(function(rev:Object):void
	{
		event.target.text=rev.personIdName;
		fparameter["maker"]=rev.personId
	}, 0, y);
}
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