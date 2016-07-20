/**
 *		 当前现存量查询条件窗体
 *		 author:周作建   2011.05.22
 *		 checked by：
 **/

import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialAcct.stat.currentStock.ModCurrentStock;
import cn.superion.materialAcct.util.MainToolBar;

import com.adobe.utils.StringUtil;

import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.ui.Keyboard;

import mx.collections.ArrayCollection;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

public var parentWin:*;
private var _stockAmountFlag:String = '';
private var _winY:int = 0;
private var _conditions:Object = {};
private var _statFlag:String = null;
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
}

/**
 * 回车到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e, fcontrolNext);
}
/**
 * 物资字典
 */
protected function materialName_queryIconClickHandler(event:Event):void
{
	var lstorageCode:String='';
	lstorageCode=(storageCode.selectedItem || {}).storageCode;
	
	DictWinShower.showMaterialDictNew(lstorageCode, '', '', true, function(fItem:Array):void
	{
		materialName.text = fItem[0].materialName;	
		_conditions['materialName'] = fItem[0].materialName;	
	}, 0, _winY);
}
/**
 * 物资分类字典
 */
protected function materialClass_queryIconClickHandler(event:Event):void
{
	DictWinShower.showMaterialClassDict(function(rev:Object):void
	{
		materialClass.text = rev.classCode;	
		_conditions['materialClass'] = rev.classCode;	
	}, 0, _winY);
}
/**
 * 回车事件
 **/
private function toNextCtrl(event:KeyboardEvent, fctrlNext:Object):void
{
	if (event.keyCode != Keyboard.ENTER)
	{
		return;
	}
	//
	FormUtils.toNextControl(event, fctrlNext);
}
/**
 * 针对按钮不同组合处理
 * */
private function chkBox_changeHandler(event:Event):void{
	if(checkBox1.selected && !checkBox2.selected && !checkBox3.selected){
		_stockAmountFlag = "1";
	}else if(checkBox2.selected && !checkBox1.selected && !checkBox3.selected){
		_stockAmountFlag = "2";
	}else if(checkBox3.selected && !checkBox1.selected && !checkBox2.selected){
		_stockAmountFlag = "3";
	}else if(checkBox1.selected && checkBox2.selected && !checkBox3.selected){
		_stockAmountFlag = "4";
	}else if(checkBox2.selected && checkBox3.selected && !checkBox1.selected){
		_stockAmountFlag = "5";
	}else if(checkBox1.selected && checkBox3.selected && !checkBox2.selected){
		_stockAmountFlag = "6";
	}else{
		event.target.selected = false;
	}
}

/**
 * 确定
 * */
protected function btConfirm_clickHandler(event:MouseEvent):void
{
	var para:ParameterObject = new ParameterObject();
	_conditions = {
//		"statFlag":_statFlag == null ?"1":_statFlag,
		"storageCode":storageCode.selectedItem?storageCode.selectedItem.storageCode:"",
		"materialClass":materialClass.text,
		"beginMaterialCode":beginMaterialCode.text,
		"endMaterialCode":endMaterialCode.text,
		"materialName":materialName.text,
		"beginAvailDate":chkMakeDate.selected?beginAvailDate.selectedDate:null,
		"endAvailDate":chkMakeDate.selected?MainToolBar.addOneDay(endAvailDate.selectedDate):null,
		"anearNum":StringUtil.trim(numDays.text).length == 0 ? null : Number(numDays.text),
		"stockAmountFlag":_stockAmountFlag
	};
	para.conditions = _conditions;
	var ro:RemoteObject = RemoteUtil.getRemoteObject(ModCurrentStock.DESTANATION,function (rev:Object):void{
		if(rev.data.length == 0) return;
		parentWin.gdItems.dataProvider = rev.data;
		parentWin.tbarMain.btExp.enabled = true;
		parentWin.tbarMain.btPrint.enabled = true;
		parentWin._storageName = storageCode.textInput.text;
		closeWin();
	});
	ro.findCurrentStockByCondition(para);
}
/**
 * 取消
 * */
protected function closeWin():void
{
	PopUpManager.removePopUp(this);
}