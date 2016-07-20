
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.ArrayCollUtils;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialAcct.util.MaterialDictShower;
import cn.superion.vo.system.SysUnitInfor;

import com.adobe.utils.StringUtil;

import flexlib.scheduling.util.DateUtil;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

import spark.events.TextOperationEvent;

private var _condition:Object={};
//上一级页面
public var parentWin:Object;

//供应商分类
private var salerClass:String="";
//生产厂家分类
private var factoryClass:String="";

/**
 *初始化方法
 * */
protected function doInit():void
{	
	fillForm();
	
	salerClass=ExternalInterface.call("getSalerClass");
	factoryClass=ExternalInterface.call("getFactoryClass");
	
	unitsCode.textInput.editable=false;
	
	var larry:ArrayCollection=new ArrayCollection([{'unitsCode':'','unitsName':'全部'}]);
	for each (var it:* in MaterialDictShower.SYS_UNITS){//SysUnitInfor
		it.unitsName = it.unitsSimpleName;
		it.unitsCode = it.unitsCode;
		larry.addItem(it);
	}
	unitsCode.dataProvider = larry;
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
	salerCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	});
	materialCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	});
	factoryCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	});
	doctor.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	});
	doctorGroup.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	});
	deptCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	});
	wardCode.txtContent.addEventListener(TextOperationEvent.CHANGING, function(e:TextOperationEvent):void
	{
		e.preventDefault();
	});
}


protected function materialCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 338;
	
	DictWinShower.showMaterialDictNew('', '', '', true, function(fItem:Array):void
	{
		var item:Object=fItem[0];
		materialCode.text=item.materialName;
		_condition.materialCode=item.materialCode;
	}, x, y);
	
}

protected function deptCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	
	MaterialDictShower.showDeptDict(function(rev:Object):void
	{
		deptCode.text=rev.deptName;
		_condition.deptCode=rev.deptCode;
		
	}, x, y);
}


protected function wardCode_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	
	MaterialDictShower.showDeptDict(function(rev:Object):void
	{
		wardCode.text=rev.deptName;
		_condition.wardCode=rev.deptCode;
		
	}, x, y);
}


protected function doctor_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	
	MaterialDictShower.showDoctorDict(function(rev:Object):void
	{
		doctor.text=rev.personIdName;
		_condition.doctor=rev.personId;
		
	}, x, y);
}


protected function doctorGroup_queryIconClickHandler(event:Event):void
{
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	
	MaterialDictShower.showDeptGroupDict(function(rev:Object):void
	{
		doctorGroup.text=rev.deptName;
		_condition.doctorGroup=rev.deptCode;
		
	}, x, y);
}

protected function factoryCode_queryIconClickHandler(event:Event):void
{
	
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	
	MaterialDictShower.showProviderDict(function(rev:Object):void
	{
		factoryCode.txtContent.text=rev.providerName;
		_condition.factoryCode=rev.providerId;
		
		
	}, x, y,null,factoryClass);
}

protected function salerCode_queryIconClickHandler(event:Event):void
{
	
	var x:int=0;
	var y:int=this.parentApplication.screen.height - 345;
	
	MaterialDictShower.showProviderDict(function(rev:Object):void
	{
		salerCode.txtContent.text=rev.providerName;
		_condition.salerCode=rev.providerId;
		
		
	}, x, y,null,salerClass);
}

/**
 * 确定
 * 
 * */
protected function btQuery_clickHandler():void
{
	_condition['unitsCode']=unitsCode.selectedItem.unitsCode;
	_condition['beginAccountDate']=btAccountDate.selected ? beginAccountDate.selectedDate : null;
	_condition['endAccountDate']=btAccountDate.selected ? addOneDay(endAccountDate.selectedDate) : null;
	_condition['patientId']=patientId.text;
	_condition['barCode']=barCode.text;
	
	var paramQuery:ParameterObject=new ParameterObject();
	paramQuery.conditions=_condition;	
	
	closeWin();
	parentWin.dict["供应商"]=salerCode.text;
	
	var ro:RemoteObject=RemoteUtil.getRemoteObject(parentWin.DESTINATION, function(rev:Object):void
	{
		var larryList:ArrayCollection=rev.data as ArrayCollection;
		var dataList:ArrayCollection=new ArrayCollection();

		for(var i:int=0;i<larryList.length;i++)
		{
			if(larryList[i].length>0)
			{
				for each(var item:Object in larryList[i])
				{
					//性别
					item.sex=item.sex=='1' ? '男' : item.sex=='2' ? '女' : '';
					//医生
					var doctorObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.personIdDict,'personId',item.doctor);
					item.doctor=doctorObj && item.doctor? doctorObj.personIdName : '';
					//科室
					var deptObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict,'dept',item.deptCode);
					item.deptCode=deptObj && item.deptCode ? deptObj.deptName : '';
					//病区
					deptObj=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict,'dept',item.wardCode);
					item.wardCode=deptObj && item.wardCode? deptObj.deptName : '';
					//医生组别
					deptObj=ArrayCollUtils.findItemInArrayByValue(BaseDict.deptDict,'dept',item.deptGroup);
					item.deptGroup=deptObj && item.deptGroup ? deptObj.deptName : '';
					//生产厂家
					var providerObj:Object=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict,'provider',item.factoryCode);
					item.factoryCode=providerObj && item.factoryCode ? providerObj.providerName : '';
					//供应商
					providerObj=ArrayCollUtils.findItemInArrayByValue(BaseDict.providerDict,'provider',item.salerCode);
					item.salerCode=providerObj && item.salerCode ? providerObj.providerName : '';
					
					item.registerAvlDate=item.registerAvlDate ? DateField.dateToString(item.registerAvlDate,'YYYY-MM-DD') : '';
					item.availDate=item.availDate ? DateField.dateToString(item.availDate,'YYYY-MM-DD') : ''
					dataList.addItem(item);
				}
			}
		}
		
		if(dataList.length>0)
		{
			setToolBarBts(dataList);
			parentWin.gdPatsMaterial.dataProvider=dataList;
		}
		else
		{
			Alert.show('没有查询到相关的材料信息','提示');
			parentWin.gdPatsMaterial.dataProvider=new ArrayCollection();
			parentWin.gdPatsMaterial.emptyLinesCount=0;
		}
	});
	ro.findPatsStatListByCondition(paramQuery);
}

/**
 * 设置工具栏的可用按钮
 */
private function setToolBarBts(larry:ArrayCollection):void
{
	if (larry.length>0)
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

private function addOneDay(date:Date):Date{
	//
	return flexlib.scheduling.util.DateUtil.addTime(new Date(date),flexlib.scheduling.util.DateUtil.DAY_IN_MILLISECONDS - 1000);
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
private function queryIcon_keyUpHandler(event:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.textInputIconKeyUpHandler(event, _condition, fcontrolNext);
}

/**
 * 关闭事件处理方法
 * */
private function closeWin():void
{
	PopUpManager.removePopUp(this);
}