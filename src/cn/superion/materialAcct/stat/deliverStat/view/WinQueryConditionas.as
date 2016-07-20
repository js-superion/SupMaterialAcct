/**
 *		 出库报告单列表查询条件窗体
 *		 author:周作建   2011.05.22
 *		 checked by：
 **/
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.ParameterObject;
import cn.superion.base.util.DateUtil;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictWinShower;
import cn.superion.materialAcct.stat.deliverStat.ModDeliverStat;
import cn.superion.materialAcct.util.MainToolBar;
import cn.superion.materialAcct.util.MaterialDictShower;

import com.adobe.utils.StringUtil;

import mx.collections.ArrayCollection;
import mx.controls.DateField;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

public var iparentWin:Object;
private var _winY:int = 0;
private var _conditions:Object = {};
//
private var _statFlag:String = null;
private var _deptCode:String = null;
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
	unitsCode.dataProvider = MaterialDictShower.SYS_UNITS;//加载泰州南北院的信息
//	unitsCode.requireSelection = true;
	_winY=this.parentApplication.screen.height - 345;
	//
	chkDeptGroup.selected = iparentWin.myViewStack.selectedChild == iparentWin.deptGroup?true:false;
	chkMaterialCode.selected =iparentWin.myViewStack.selectedChild == iparentWin.materialGroup?true:false;
	if(iparentWin.myViewStack.selectedChild ==iparentWin.deptMaterialGroup){
		chkDeptGroup.selected = true;
		chkMaterialCode.selected = true;
	}
	
}
/**
 * 处理回车键转到下一个控件
 * */
private function toNextControl(e:KeyboardEvent, fcontrolNext:Object):void
{
	FormUtils.toNextControl(e, fcontrolNext);
}
/**
 * 部门字典
 */
protected function dept_queryIconClickHandler(event:Event):void
{
	MaterialDictShower.showDeptDict(function(rev:Object):void
	{
		deptCode.text = rev.deptName;	
		_deptCode = rev.deptCode;	
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
			_maker= rev.personId;
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
	//根据所所选择的方式切换不同的表格
	if (chkDeptGroup.selected && chkMaterialCode.selected)
	{
		iparentWin.myViewStack.selectedChild=iparentWin.deptMaterialGroup;
		_statFlag = "3";
	}
	else if (chkDeptGroup.selected && !chkMaterialCode.selected)
	{
		iparentWin.myViewStack.selectedChild=iparentWin.deptGroup;
		_statFlag = "1";
	}
	else if(!chkDeptGroup.selected && chkMaterialCode.selected)
	{
		iparentWin.myViewStack.selectedChild=iparentWin.materialGroup1;
		_statFlag = "2";
	}
	else if (!chkDeptGroup.selected && !chkMaterialCode.selected) //按照物资编码分组，加发票号、发票日期等；
	{
		iparentWin.myViewStack.selectedChild=iparentWin.materialGroup;
		_statFlag = "4";
	}
	var para:ParameterObject = new ParameterObject();
	_conditions = {
			"statFlag":_statFlag == null ?"1":_statFlag,
			"deptUnitsCode":StringUtil.trim(unitsCode.textInput.text).length == 0 ? null:unitsCode.selectedItem.unitsCode,
			"deptCode":_deptCode == null ?null:_deptCode,
			"beginMaterialClass":_beginMaterialClass == null ?null:_beginMaterialClass,
			"endMaterialClass":_endMaterialClass == null ?null:_endMaterialClass,
			"materialCode":_materialName == null ?null:_materialName,
			"maker":_maker == null ?null:_maker,
			"accounter":_accounter == null ?null:_accounter,
			
			"storageCode":storageCode.selectedItem?storageCode.selectedItem.storageCode:"",
			
			"beginRdBillNo":beginRdBillNo.text == ""?endRdBillNo.text:beginRdBillNo.text,
			"endRdBillNo":endRdBillNo.text == ""?beginRdBillNo.text:endRdBillNo.text,
			"beginBillDate":chkInvoiceDate.selected?beginInvoiceDate.selectedDate:null, //这里的invoiceDate传到服务端 变为 出库单的出库日期，即：billDate；
			"endBillDate":chkInvoiceDate.selected?MainToolBar.addOneDay(endInvoiceDate.selectedDate):null,
			
			"beginMaterialClass":beginMaterialClass.text,
			"endMaterialClass":endMaterialClass.text,
			"materialName":materialName.text,
			
			"beginMakeDate":chkMakeDate.selected?beginMakeDate.selectedDate:null,
			"endMakeDate":chkMakeDate.selected?MainToolBar.addOneDay(endMakeDate.selectedDate):null,
			"beginAccountDate":chkVerifyDate.selected?beginVerifyDate.selectedDate:null,
			"endAccountDate":chkVerifyDate.selected?MainToolBar.addOneDay(endVerifyDate.selectedDate):null,
			"specialSign":specialSign.selected?'1':'',
			"commanSign":commanSign.selected?'1':''
	};
	para.conditions = _conditions;
	var ro:RemoteObject = RemoteUtil.getRemoteObject(ModDeliverStat.DESTANATION,function (rev:Object):void{
		if(rev.data.length == 0) {
			if(_statFlag=="1")
			{
				iparentWin.gdDeptGroup.dataProvider=new ArrayCollection();
			}
			else if(_statFlag=="2")
			{
				iparentWin.gdMasterialGroup1.dataProvider=new ArrayCollection();
			}
			else if(_statFlag=="3")
			{
				iparentWin.gdDeptMaterialGroup.dataProvider=new ArrayCollection();
			}
			else if(_statFlag=="4")
			{
				iparentWin.gdDeptMaterialGroup.dataProvider=new ArrayCollection();
			}
			iparentWin.tbarMain.btExp.enabled = false;
			iparentWin.tbarMain.btPrint.enabled = false;
			return;
		}
		//关闭
		btReturn_clickHandler(null);
		if(_statFlag=="1")
		{
 			iparentWin.gdDeptGroup.dataProvider=rev.data[0];
			iparentWin.gdDeptGroup.sortableColumns="true"
		}
		else if(_statFlag=="2")
		{
			iparentWin.gdMasterialGroup1.dataProvider=rev.data[0];
			iparentWin.gdMasterialGroup1.sortableColumns="true"
		}
		else if(_statFlag=="3")
		{
			iparentWin.gdDeptMaterialGroup.dataProvider=rev.data[0];
			iparentWin.gdDeptMaterialGroup.sortableColumns="true"
		}
		else if(_statFlag=="4")
		{
			iparentWin.gdMasterialGroup.dataProvider=rev.data[0];
			iparentWin.gdMasterialGroup.sortableColumns="true"
		}
		iparentWin.tbarMain.btExp.enabled = true;
		iparentWin.tbarMain.btPrint.enabled = true;
		iparentWin.deptName.text = deptCode.text;
		iparentWin.max=rev.data[1][0][2];
		iparentWin.mit=rev.data[1][0][3];
		iparentWin.selectedUnitsName = StringUtil.trim(unitsCode.textInput.text).length == 0 ? null:unitsCode.selectedItem.unitsSimpleName,
		fillValueToReport();
	});
	ro.findDeliverStatByCondition(para);
}

/**
 * 将弹出框的值给将要打印的报表
 * */
private function fillValueToReport():void{
	iparentWin._statFlag = _statFlag; 
	//将弹出页面的部分值赋予主页面
	iparentWin._deptName = deptCode.txtContent.text;
	//
	iparentWin._billDate = 
		"从："+(chkInvoiceDate.selected?DateUtil.dateToString(beginMakeDate.selectedDate,'YYYY-MM-DD'):"") 
		+ "到："
		+(chkInvoiceDate.selected?DateUtil.dateToString(endMakeDate.selectedDate,'YYYY-MM-DD'):"");
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