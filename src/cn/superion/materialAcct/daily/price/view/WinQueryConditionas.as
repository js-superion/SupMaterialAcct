/**
 *		 入库报告单列表查询条件窗体
 *		 author:周作建   2011.05.22
 *		 checked by：
 **/

import cn.superion.base.util.FormUtils;

import mx.managers.PopUpManager;


/**
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e, fcontrolNext);
}

import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.rpc.remoting.RemoteObject;
private var fparameter:Object={};
private var winY:int=0;
public var data:Object;
/**
 * 确认按钮
 */ 
protected function btConfirm_clickHandler(event:MouseEvent):void
{
	// TODO Auto-generated method stub
	fparameter["beginBillNo"]=beginBillNo.text==""?null:beginBillNo.text;
	fparameter["endBillNo"]=endBillNo.text==""?null:endBillNo.text;
	fparameter["beginBillDate"]=chkBillDate.selected?beginBillDate.text:null;
	fparameter["endBillDate"]=chkBillDate.selected?endBillDate.text:null;;
	fparameter["beginMakeDate"]=chkMakeDate.selected?beginMakeDate.text:null;
	fparameter["endMakeDate"]=chkMakeDate.selected?endMakeDate.text:null;
	fparameter["beginMaterialCode"]=beginMaterialCode.text==""?null:beginMaterialCode.text;
	fparameter["endMaterialCode"]=endMaterialNo.text==""?null:beginMaterialCode.text;
	var paramsQuery:ParameterObject=new ParameterObject();
	paramsQuery.conditions=fparameter;
	var ro:RemoteObject=RemoteUtil.getRemoteObject("materialAcctChangeImpl", function(rev:Object):void
	{
		if (rev.data && rev.data.length > 0)
		{		
			data.parentWin.arrayAutoId=	ArrayCollection(rev.data).toArray();;
			data.parentWin.findRdsById(rev.data[0]);
			setToolBarPageBts(rev.data.length);
			return;
		}
		Alert.show("没有相关数据","提示");
		//清空当前表单
		data.parentWin.clearForm(true, true);
		data.parentWin.doInit();
	});
	ro.findByConditon(paramsQuery);
	PopUpManager.removePopUp(this);
}
/**
 * 设置当前按钮是否显示
 */
private function setToolBarPageBts(flenth:int):void
{
	data.parentWin.toolBar.queryToPreState()
	
	if (flenth < 2)
	{
		data.parentWin.toolBar.btFirstPage.enabled=false
		data.parentWin.toolBar.btPrePage.enabled=false
		data.parentWin.toolBar.btNextPage.enabled=false
		data.parentWin.toolBar.btLastPage.enabled=false
		return;
	}
	data.parentWin.toolBar.btFirstPage.enabled=false
	data.parentWin.toolBar.btPrePage.enabled=false
	data.parentWin.toolBar.btNextPage.enabled=true
	data.parentWin.toolBar.btLastPage.enabled=true
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
	}, winY, y);
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
	}, winY, y);
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
	}, winY, y);
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
	}, winY, y);
}


protected function btReturn_clickHandler(event:MouseEvent):void
{
	closeWin();
}
/**
 * 取消按钮事件响应方法
 * */
protected function closeWin():void
{
	PopUpManager.removePopUp(this);
}