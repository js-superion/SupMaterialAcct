import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.config.BaseDict;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.materialAcct.stat.valueStock.view.WinQueryCondition;
import cn.superion.materialAcct.util.DefaultPage;
import cn.superion.materialAcct.util.MaterialDictShower;
import cn.superion.materialAcct.util.ToolBar;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.system.SysUnitInfor;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

public const DESTINATION:String='acctValueStockStatImpl';
private const MENU_NO:String="0211";
public var dict:Dictionary=new Dictionary();

/**
 * 初始化
 * */
protected function doInit():void
{	
	this.parentDocument.title="高值现存量查询";
	initToolBar();
		
	var ro:RemoteObject = RemoteUtil.getRemoteObject("unitInforImpl",function(rev:Object):void{
		if(rev.data.length > 0 ){
			for each (var it:SysUnitInfor in rev.data){
				it.label = it.unitsSimpleName;
				it.data = it.unitsCode;
			}
			MaterialDictShower.SYS_UNITS = rev.data;
		}
	});
	ro.findByEndSign("1");
	MaterialDictShower.getAdvanceDictList();
}

/**
 * 初始化工具栏
 * */
private function initToolBar():void
{
	var laryDisplays:Array=[toolBar.btPrint, toolBar.btExp, toolBar.imageList1, toolBar.btQuery, toolBar.imageList6, toolBar.btExit];
	var laryEnables:Array=[toolBar.btExit, toolBar.btQuery];
	ToolBar.showSpecialBtn(toolBar, laryDisplays, laryEnables, true);
}

/**
 * 打印
 */
protected function printClickHandler(event:Event):void
{
	if(checkUserRole('05'))
	{
		printReport("1");
	}
	else return
}



/**
 * 输出
 */
protected function expClickHandler(event:Event):void
{
	if(checkUserRole('08'))
	{
		printReport("0");
	}
}

protected function printReport(printSign:String):void
{
	var dataList:ArrayCollection=gdCurrentStock.dataProvider as ArrayCollection;
	
	dict["主标题"]="高值耗材现存量";
	
	dict["单位"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	
	dict["制单人"]=AppInfo.currentUserInfo.userName;
	
	var url:String="report/materialAcct/stat/valueStock/valueStockStat.xml"
	
	if (printSign == '1')
	{
		ReportPrinter.LoadAndPrint(url, dataList, dict);
	}
	else
	{
		ReportViewer.Instance.Show(url, dataList, dict);
	}
}

/**
 * 查询按钮功能
 * */
protected function queryClickHandler(event:Event):void
{
	var queryWin:WinQueryCondition=PopUpManager.createPopUp(this, WinQueryCondition, true) as WinQueryCondition;
	queryWin.parentWin=this;
	FormUtils.centerWin(queryWin);
	
}

/**
 * 当前角色权限认证
 */
private function checkUserRole(role:String):Boolean
{
	//判断具有操作权限  -- 应用程序编号，菜单编号，权限编号
	// 01：增加                02：修改            03：删除
	// 04：保存                05：打印            06：审核
	// 07：弃审                08：输出            09：输入
	if (!PurviewUtil.getPurview(AppInfo.APP_CODE, MENU_NO,role))
	{
		Alert.show("您无此按钮操作权限！", "提示");
		return false;
	}
	return true;
}

/**
 * 退出按钮
 * */
protected function exitClickHandler(event:Event):void
{
	if (this.parentDocument is WinModual)		
	{
		PopUpManager.removePopUp(this.parentDocument as IFlexDisplayObject);
		return;
	}
	DefaultPage.gotoDefaultPage();
}