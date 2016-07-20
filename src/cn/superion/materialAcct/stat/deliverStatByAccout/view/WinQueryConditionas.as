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
import cn.superion.materialAcct.stat.deliverStatByAccout.ModDeliverStatByAccount;
import cn.superion.materialAcct.util.MainToolBar;
import cn.superion.materialAcct.util.MaterialDictShower;

import com.adobe.utils.StringUtil;

import flash.utils.Endian;

import mx.collections.ArrayCollection;
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
	unitsCode.dataProvider = MaterialDictShower.SYS_UNITS;//加载泰州南北院的信息
	_winY=this.parentApplication.screen.height - 345;
	
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
	var para:ParameterObject = new ParameterObject();
	_conditions = {
			"deptUnitsCode":StringUtil.trim(unitsCode.textInput.text).length == 0 ? null:unitsCode.selectedItem.unitsCode,
			"deptCode":_deptCode == null ?null:_deptCode,
			"accounter":_accounter == null ?null:_accounter,
			
			"beginBillDate":chkInvoiceDate.selected?beginInvoiceDate.text:null, //这里的invoiceDate传到服务端 变为 出库单的出库日期，即：billDate；
			"endBillDate":chkInvoiceDate.selected?endInvoiceDate.text:null,
			
			"beginMakeDate":chkMakeDate.selected?beginMakeDate.text:null,
			"endMakeDate":chkMakeDate.selected?endMakeDate.text:null,
			"beginAccountDate":chkVerifyDate.selected?beginVerifyDate.text:null,
			"endAccountDate":chkVerifyDate.selected?endVerifyDate.text:null
	};
	para.conditions = _conditions;
	var ro:RemoteObject = RemoteUtil.getRemoteObject(ModDeliverStatByAccount.DESTANATION,function (rev:Object):void{
		if(rev.data.length == 0) {
			iparentWin.gridAntibacterialList1.dataProvider = new ArrayCollection();
			return;
		}
		//关闭
		btReturn_clickHandler(null);
		var newAryCol:ArrayCollection = new ArrayCollection();
		for each (var it:Object in rev.data[0]){
			var obj:Object = new Object();
			obj.charge1 =it[2];
			obj.charge2 = it[3];
			obj.charge3 = it[4];
			obj.charge4 = it[5];
			obj.charge5 = it[6];
			obj.charge6 = it[7];
			obj.charge7 = it[8];
			obj.charge8 = it[9];
			obj.charge9 = it[10];
			obj.charge10 = it[11];
			obj.deptUnitsCode = it[0];
			obj.deptCode = it[1];
			newAryCol.addItem(obj);
		}
		
		reCreateDataFromRemote(newAryCol);
 		iparentWin.gridAntibacterialList1.dataProvider=newAryCol;
		iparentWin.gridAntibacterialList1.sortableColumns="true"
		iparentWin.tbarMain.btExp.enabled = true;
		iparentWin.tbarMain.btPrint.enabled = true;
		iparentWin.deptName.text = deptCode.text;
		iparentWin.selectedUnitsName = StringUtil.trim(unitsCode.textInput.text).length == 0 ? null:unitsCode.selectedItem.unitsSimpleName;
		fillValueToReport();
	});
	ro.findDeliverStatByAccount(para);
}


/**
 * 添加合计
 * */
private function reCreateDataFromRemote(faryCol:ArrayCollection):ArrayCollection
{
	var charge01:Number = 0; 
	var charge02:Number = 0; 
	var charge03:Number = 0; 
	var charge04:Number = 0; 
	var charge05:Number = 0;
	var charge06:Number = 0; 
	var charge07:Number = 0; 
	var charge08:Number = 0; 
	var charge09:Number = 0; 
	var charge10:Number = 0; 
	for each (var item:Object in faryCol)
	{
		//合计
		
		charge01 += Number(item.charge1); 
		charge02 += Number(item.charge2);
		charge03 += Number(item.charge3);
		charge04 += Number(item.charge4); 
		charge05 += Number(item.charge5);
		charge06 += Number(item.charge6);
		charge07 += Number(item.charge7); 
		charge08 += Number(item.charge8);
		charge09 += Number(item.charge9);
		charge10 += Number(item.charge10);
	}
	
	//添加合计行
	var sumRow:Object = {unitsSimpleName:'',deptCode:'',
		charge1:charge01.toFixed(2),charge2:charge02.toFixed(2),charge3:charge03.toFixed(2),
			charge4:charge04.toFixed(2),charge5:charge05.toFixed(2),charge6:charge06.toFixed(2),
			charge7:charge07.toFixed(2),charge8:charge08.toFixed(2),charge9:charge09.toFixed(2),
			charge10:charge10.toFixed(2)};
	faryCol.addItem(sumRow);
	return faryCol;
}

/**
 * 将弹出框的值给将要打印的报表
 * */
private function fillValueToReport():void{
	//将弹出页面的部分值赋予主页面
	iparentWin._deptName = deptCode.txtContent.text;
	//
	iparentWin._billDate1 = beginInvoiceDate.selectedDate;
	iparentWin._billDate2 = endInvoiceDate.selectedDate;
}
/**
 * 返回
 */
protected function btReturn_clickHandler(event:MouseEvent):void
{
	PopUpManager.removePopUp(this);
}