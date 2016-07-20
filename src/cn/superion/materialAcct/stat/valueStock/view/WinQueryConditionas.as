/**
 *	 现存量查询模块
 *   author: 芮玉红  2012.11.29
 **/
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialAcct.util.MaterialDictShower;

import flexlib.scheduling.util.DateUtil;

import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.TextOperationEvent;

public var parentWin:Object;
//条件对象
private var _condition:Object={};

private function doInit():void
{
	fillForm();
	preventDefaultForm();
	storageCode.txtContent.setFocus();
	
}

/**
 * 填充表单
 * */
private function  fillForm():void{
	FormUtils.fillFormByItem(this,_condition);
}

/**
 * 阻止放大镜表格输入内容
 */
private function preventDefaultForm():void
{
	storageCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
		
	materialClass.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
	
	materialName.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	})
}

/**
 *科室字典
 */
protected function deptCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	MaterialDictShower.showDeptDict((function(rev:Object):void
	{
		storageCode.txtContent.text=rev.deptName;
		_condition['storageCode']=rev.deptCode;
	}), x, y);
}

/**
 *物资分类字典
 */
protected function materialClass_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	DictWinShower.showMaterialClassDict((function(rev:Object):void
	{
		materialClass.txtContent.text=rev.className;
		_condition['materialClass']=rev.classCode;
	}), x, y);
}

/**
 *物资档案字典
 */
protected function materialName_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	MaterialDictShower.showMaterialValueDict((function(rev:Object):void
	{
		materialName.txtContent.text=rev.materialName;
		_condition['materialName']=rev.materialName;
	}), x, y);
}
/**
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e,fcontrolNext);
}

/**
 * 放大镜键盘事件处理方法
 * */
protected function queryIcon_keyUpHandler(event:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.textInputIconKeyUpHandler(event, _condition, fcontrolNext);
}

/**
 * 查询
 * */
public function btQuery_clickHandler():void
{
	_condition["materialCode"]=materialCode.text;
	//现存量
	_condition["minStockAmount"]=minStockAmount.text== "" ? null : Number(minStockAmount.text);
	_condition["maxStockAmount"]=maxStockAmount.text=="" ? null  : Number(maxStockAmount.text);
	
	parentWin.dict["物资分类"]=materialClass.txtContent.text;
	if(minStockAmount.text || maxStockAmount.text)
	{
		parentWin.dict["现存量范围"]=minStockAmount.text+" - "+maxStockAmount.text;
	}
	
	//有效期限范围
	_condition['beginAvailDate']=availDate.selected ? beginAvailDate.selectedDate: null;
    _condition['endAvailDate']=availDate.selected ?  addOneDay(endAvailDate.selectedDate) : null;
	
	var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions=_condition;
	PopUpManager.removePopUp(this);
	
	var ro:RemoteObject=RemoteUtil.getRemoteObject(parentWin.DESTINATION, function(rev:Object):void
	{
		setToolBarBts(rev);
		for(var i:int=0; i<rev.data.length; i++)
		{
			var item:Object=rev.data.getItemAt(i);
	
			item.tradeMoney=item.amount * item.tradePrice;
			item.nameSpecFactory = item.materialName + " "+(item.materialSpec == null ? "" : item.materialSpec)+" "+(item.factoryName == null ? "" : item.factoryName.substr(0,6));
			item.storageName=item.storageCode==null ? "" :ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict,'dept',item.storageCode).deptName;
		}
		parentWin.gdCurrentStock.dataProvider=rev.data;
		
	});
	ro.findValueStockByCondition(paramQuery);
	parentWin.gdCurrentStock.dataProvider=null;
}



public static function addOneDay(date:Date):Date{
	//
	return flexlib.scheduling.util.DateUtil.addTime(new Date(date),flexlib.scheduling.util.DateUtil.DAY_IN_MILLISECONDS - 1000);
}

/**
 * 设置工具栏的可用按钮
 */
private function setToolBarBts(rev:Object):void
{
	if (rev.data && rev.data.length)
	{
		parentWin.toolBar.btPrint.enabled=true;
		parentWin.toolBar.btExp.enabled=true;
	}
	else
	{
		parentWin.toolBar.btPrint.enabled=false;
		parentWin.toolBar.btExp.enabled=false;
	}
}

/**
 * 关闭事件处理方法
 * */
protected function closeWin():void
{
	PopUpManager.removePopUp(this);
}