import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.RemoteUtil;
import cn.superion.dataDict.DictDataProvider;
import cn.superion.materialAcct.util.MaterialDictShower;
import cn.superion.vo.system.SysRoleData;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.remoting.mxml.RemoteObject;

private var currentWin:Login;

//重新注册客户端对应的服务端类
registerClassAlias("cn.superion.system.entity.SysRoleData", cn.superion.vo.system.SysRoleData);

//初始当前窗口
protected function init():void
{
	ExternalInterface.call("setTitle", AppInfo.APP_NAME);
	ExternalInterface.call("setFlexFocus");

	currentWin=this;

	userCode.setFocus();

	//加载当前基础数据字典
	DictDataProvider.init();
	//判断是否开发模式
	if (AppInfo.APP_MODE)
	{
		userCode.text="3799";
		password.text="123456";
		checkCode.text=vcheckCode.text;
	}
	//验证码不输入时
	checkCode.text=vcheckCode.text;
}


protected function exitBt_clickHandler(event:MouseEvent):void
{
	ExternalInterface.call('closeIE');
}

//登录按钮
protected function loginBt_clickHandler(event:Object):void
{
	if (password.text == '')
	{
		password.setFocus();
		return;
	}
	if (checkCode.text.toLowerCase() != vcheckCode.text.toLowerCase())
	{
		vcheckCode.drawVCode();
		checkCode.setFocus();
		Alert.show("验证码不正确", "提示");
		return;
	}
	if (unitsDdlb.selectedIndex < 1)
	{
		unitsDdlb.setFocus();
		Alert.show("请您选择单位", "提示");
		return;
	}
	if (rolesDdlb.selectedIndex < 1)
	{
		rolesDdlb.setFocus();
		Alert.show("请您选择角色", "提示");
		return;
	}
	//				vcheckCode.drawVCode();
	submitLogin();
}

//用户登录
private function submitLogin():void
{
	var inputCode:String;
	if (inputTypeCode.selectedValue == '拼音码')
	{
		inputCode='PHO_INPUT';
	}
	else
	{
		inputCode='FIVE_INPUT';
	}
	ExternalInterface.call("setTitle", AppInfo.APP_NAME)
	var ro:RemoteObject=RemoteUtil.getRemoteObject("loginImpl", function(rev:Object):void
	{
		//登录成功后，进行客户端数据处理
		AppInfo.currentUserInfo=rev.data[0];
		AppInfo.currentUserInfo.isOutModual == '1';
		PopUpManager.removePopUp(currentWin);
		parentApplication.mainWin.visible=true;

		parentApplication.mainWin.toolBar.userName.text=AppInfo.currentUserInfo.unitsName + ' ' + AppInfo.currentUserInfo.userName;

		//加载高级字典数据
		DictDataProvider.initAdvance();
		ExternalInterface.call("setTitle", AppInfo.APP_NAME + ' Ver-' + AppInfo.currentUserInfo.appVersion);
		
		//是否加载多个单位下的基础字典 ryh 13.01.21，泰州需要加载
		MaterialDictShower.isAllUnitsDict=ExternalInterface.call("getIsAllUnitsDict");
		
		if(MaterialDictShower.isAllUnitsDict)
		{
			MaterialDictShower.getAdvanceDictList();
		}
	});

	ro.doLogin(userCode.text, password.text, unitsDdlb.selectedItem.unitsCode, unitsDdlb.selectedItem.unitsName, rolesDdlb.selectedItem.roleCode, inputCode, AppInfo.APP_CODE);
}

//用户编号失去焦点时的情况
protected function userCode_focusOutHandler(event:FocusEvent):void
{
	if (userCode.text == "")
	{
		userCode.setFocus();
		return;
	}

	var ro:RemoteObject=RemoteUtil.getRemoteObject("loginImpl", fillUnitsRoles);
	ro.isUser(userCode.text);
}

//判断用户，并填充单位和角色
private function fillUnitsRoles(rev:Object):void
{
	if (rev.data && rev.data.length > 0)
	{
		//用户信息
		AppInfo.currentUserInfo=rev.data[0].userInfo;
		AppInfo.currentUserInfo.isOutModual == '1'
		//根据当前用户信息中的输入法
		if (AppInfo.currentUserInfo.inputCode == 'PHO_INPUT')
		{
			phoInputType.selected=true;
			fiveInputType.selected=false;
		}
		else
		{
			phoInputType.selected=false;
			fiveInputType.selected=true;
		}

		//用户授权单位
		var obj:Object={unitsName: '--请选择单位--', unitsCode: ''};
		var laryDepList:ArrayCollection=rev.data[0].userUnits;

		laryDepList.addItemAt(obj, 0);
		unitsDdlb.dataProvider=laryDepList;
		if (laryDepList.length == 2)
		{
			unitsDdlb.selectedIndex=1;
		}
		else
		{
			unitsDdlb.selectedIndex=0;
		}

		//用户授权角色
		obj={roleName: '--请选择角色--', roleCode: ''};
		var laryRoleList:ArrayCollection=rev.data[0].userRoles;

		laryRoleList.addItemAt(obj, 0);
		rolesDdlb.dataProvider=laryRoleList;
		if (laryRoleList.length == 2)
		{
			rolesDdlb.selectedIndex=1;
		}
		else
		{
			rolesDdlb.selectedIndex=0;
		}
	}
}

//回车事件
protected function keyDownCtrl(event:KeyboardEvent, ctrl:Object):void
{
	if (event.keyCode == 13)
	{
		if (event.currentTarget == password)
		{
			passwordLogin();
			return;
		}
		else if (event.currentTarget == unitsDdlb)
		{
			passwordLogin();
			return;
		}
		else if (event.currentTarget == rolesDdlb)
		{
			passwordLogin();
			return;
		}
		else
		{
			ctrl.setFocus();
		}
	}
}

/**
 * 密码回车直接登录，同登录按钮不同之处去掉部分提示
 */
private function passwordLogin():void
{
	if (password.text == '')
	{
		password.setFocus();
		return;
	}
	if (checkCode.text.toLowerCase() != vcheckCode.text.toLowerCase())
	{
		vcheckCode.drawVCode();
		checkCode.setFocus();
		Alert.show("验证码不正确", "提示");
		return;
	}
	if (unitsDdlb.selectedIndex < 1)
	{
		unitsDdlb.setFocus();
		return;
	}
	if (rolesDdlb.selectedIndex < 1)
	{
		rolesDdlb.setFocus();
		return;
	}
	//				vcheckCode.drawVCode();
	submitLogin();
}
