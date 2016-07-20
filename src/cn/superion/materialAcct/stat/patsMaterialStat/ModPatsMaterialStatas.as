import cn.superion.base.components.controls.WinModual;
import cn.superion.base.config.AppInfo;
import cn.superion.base.util.FormUtils;
import cn.superion.base.util.PurviewUtil;
import cn.superion.base.util.RemoteUtil;
import cn.superion.materialAcct.stat.patsMaterialStat.view.WinPatsMaterialQuery;
import cn.superion.materialAcct.util.DefaultPage;
import cn.superion.materialAcct.util.MaterialDictShower;
import cn.superion.report2.ReportPrinter;
import cn.superion.report2.ReportViewer;
import cn.superion.vo.system.SysUnitInfor;

import com.as3xls.xls.ExcelFile;
import com.as3xls.xls.Sheet;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.controls.DateField;
import mx.core.IFlexDisplayObject;
import mx.managers.PopUpManager;
import mx.rpc.remoting.RemoteObject;

public const DESTINATION:String='acctPatsMaterialStatImpl';
private const MENU_NO:String="0210";
public var dict:Dictionary=new Dictionary();
[Bindable]
private var _gridWidth:int=0;
[Bindable]
private var _gridHeight:int=0;

/**
 * 初始化
 * */
protected function doInit():void
{	
	getScreenWidth();
	this.parentDocument.title="病人使用材料查询";
	initToolBar();
	var sumCount:Number=0;
	gdPatsMaterial.sumItemCallBack = function(item:Object):void{
		if(item._amount && item.isSum)
		{
			sumCount+=item.amount;
			item.barCode=item.isSum?'共'+item.itemCount+'项':"";
		}
		else if(item._amount)
		{
			item.barCode=item.isSum?'共'+sumCount+'项':"";
			item.amount=sumCount;
		}
		
	}
	if(MaterialDictShower.isAllUnitsDict)
	{
		MaterialDictShower.getAdvanceDictList();
	}
	
	var ro:RemoteObject = RemoteUtil.getRemoteObject("unitInforImpl",function(rev:Object):void{
		if(rev.data.length > 0 ){
			for each (var it:* in rev.data){//SysUnitInfor
				it.label = it.unitsSimpleName;
				it.data = it.unitsCode;
			}
			MaterialDictShower.SYS_UNITS = rev.data;
		}
	});
	ro.findByEndSign("1");
}


private function getScreenWidth():void
{
	_gridWidth=this.parentApplication.width-10;
	_gridHeight=this.parentApplication.height-100;
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


protected function printReport(printSign:String):void
{
	var dataList:ArrayCollection=gdPatsMaterial.dataProvider as ArrayCollection;
	
	for each(var item:Object in dataList)
	{
		item.materialSpec=item.materialSpec ? item.materialSpec : '';
		item.materialUnits=item.materialUnits ? item.materialUnits : '';
		item.materialDetail=item.materialSpec + " " + item.materialUnits;
	}
	dict["主标题"]="病人使用材料";
	
	dict["单位"]=AppInfo.currentUserInfo.unitsName;
	dict["日期"]=DateField.dateToString(new Date(), 'YYYY-MM-DD');
	
	dict["制单人"]=AppInfo.currentUserInfo.userName;
	
	var strUrl:String="report/materialAcct/stat/patsMaterial/patsMaterialStat.xml"
	
	if (printSign == '1')
	{
		ReportPrinter.LoadAndPrint(strUrl, dataList, dict);
	}
	else
	{
		ReportViewer.Instance.Show(strUrl, dataList, dict);
	}
}


/**
 * 输出
 */
protected function expClickHandler(event:Event):void
{
	expExcel();
}

private function expExcel():void
{
	var laryGroupData:Array=gdPatsMaterial.groupDataProvider as Array
	var cols:Array=gdPatsMaterial.columns
	var excelFile:ExcelFile = new ExcelFile();
	var sheet:Sheet = new Sheet();
	if(gdPatsMaterial.dataProvider == null){
		return;
	}
	sheet.resize(gdPatsMaterial.dataProvider.length+laryGroupData.length+1,cols.length)
	addExcelHeader(gdPatsMaterial,sheet);
	addExcelData(laryGroupData,sheet);
	excelFile.sheets.addItem(sheet);
	var mbytes:ByteArray = excelFile.saveToByteArray();
	var  file:FileReference=new FileReference()
	
	var excelTitle:String='病人使用材料统计';
	
	file.save(mbytes,excelTitle+".xls");
	
	
}

private function addExcelHeader(gridList:Object,fsheet:Sheet):void{
	var cols:Array=gdPatsMaterial.columns
	var i:int=0;
	for each(var col:GridColumn in cols){
		fsheet.setCell(0,i,col.headerText)
		i++
	}
}

private function addExcelData(laryGroupData:Array,fsheet:Sheet):void{
	var lintRow:int=1;
	var cols:Array=gdPatsMaterial.columns
	for each(var lgroup:Object in laryGroupData){
		lgroup.keyMirror='-1'
		for each(var litem:Object in lgroup.list){
			
			for(var i:int=0;i<cols.length;i++)
			{
				if(i==0)
				{
					if(lgroup.keyMirror=='-1'){
						lgroup.keyMirror=lgroup.key
					}
					fsheet.setCell(lintRow,i,lgroup.keyMirror);
					lgroup.keyMirror=''
				}
				else if(i==1 || i==2)
				{
					fsheet.setCell(lintRow,i,litem[cols[i].dataField]+"_" || '');
				}
				else
				{
					fsheet.setCell(lintRow,i,litem[cols[i].dataField] || '');
				}
				
			}
			lintRow++;
		}
	}
}


/**
 * 查询按钮功能
 * */
protected function queryClickHandler(event:Event):void
{
	var queryWin:WinPatsMaterialQuery=PopUpManager.createPopUp(this, WinPatsMaterialQuery, true) as WinPatsMaterialQuery;
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