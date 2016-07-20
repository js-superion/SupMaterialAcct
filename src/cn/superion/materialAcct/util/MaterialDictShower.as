package cn.superion.materialAcct.util
{
	import cn.superion.base.components.controls.SimpleDictWin;
	import cn.superion.base.config.BaseDict;
	import cn.superion.base.config.SimpleDictWinConfig;
	import cn.superion.base.util.RemoteUtil;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	import mx.core.FlexGlobals;
	import mx.managers.PopUpManager;
	import mx.rpc.remoting.RemoteObject;

	public class MaterialDictShower
	{
		public static var SYS_UNITS:ArrayCollection = null;
		//是否加载多个单位下的基础字典 ryh 13.01.21，泰州需要加载
		public static var isAllUnitsDict:Boolean=false;

		/**
		 * 显示批号选择对话框
		 * 用法：MaterialDictShower.showBatchNoChooser("123","234","123",function(it){})
		 * */
		public static function showBatchNoChooser(fmaterialId:String, fstorageCode:String, fbatch:String, callback:Function, x:int=-1, y:int=-1):void
		{
			var config:SimpleDictWinConfig=new SimpleDictWinConfig();
			config.destination='commMaterialServiceImpl';
			config.method="findCurrentStockByFactoryBatch";

			config.gridDataFields=["materialCode", "materialName", "materialSpec", "materialUnits", "tradePrice", "amount", "factoryName", "madeDate", "batch", "availDate"];
			config.gridHeadTexts=["物资编码", "物资名称", "规格型号", "单位", "进价", "现存量", "生产企业", "生产日期", "批号", "有效期至"];
			config.gridDataQueryOption=[{label: '批号', field: 'batch', value: fbatch}];
			config.typeName="批号查询";
			config.baseCondition={materialId: fmaterialId, storageCode: fstorageCode}
			config.widths=[1.3, 2, 1.2, 1, 1, 1, 3, 1.5, 1, 1.5];
			config.initQueryValue=fbatch
			config.callback=callback;
			var win:SimpleDictWin=SimpleDictWin(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), SimpleDictWin));
			win.height=340;
			win.width=896;
			win.dictWinConfig=config;
			if (x == -1)
			{
				PopUpManager.centerPopUp(win);
			}
			else
			{
				win.x=x;
				win.y=y;
			}
		}
		
		/**
		 * 显示收发类别显示；这里显示的rdFlag 为 1 即：所有入库的分类；
		 * 用法：MaterialDictShower.showReceiveTypeDict(function(it){})
		 * */
		public static function showReceiveTypeDict(callback:Function, x:int=-1, y:int=-1):void
		{
			var config:SimpleDictWinConfig=new SimpleDictWinConfig();
			config.destination='commMaterialServiceImpl';
			config.method="findOperationTypeByCondition";
			config.gridDataFields=["rdCode", "rdName"];
			config.gridHeadTexts=["编码","名称"];
			config.typeName="入库类别查询";
			config.baseCondition = {'rdFlag':"1"};
			config.widths=[1,2];
			config.callback=callback;
			var win:SimpleDictWin=SimpleDictWin(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), SimpleDictWin));
			win.height=340;
			win.width=500;
			win.dictWinConfig=config;
			if (x == -1)
			{
				PopUpManager.centerPopUp(win);
			}
			else
			{
				win.x=x;
				win.y=y;
			}
		}	
		
		/**
		 * 显示收发类别显示；这里显示的rdFlag 为 2 即：所有出库的分类；
		 * 用法：MaterialDictShower.showDeliverTypeDict(function(it){})
		 * */
		public static function showDeliverTypeDict(callback:Function, x:int=-1, y:int=-1):void
		{
			var config:SimpleDictWinConfig=new SimpleDictWinConfig();
			config.destination='commMaterialServiceImpl';
			config.method="findOperationTypeByCondition";
			config.gridDataFields=["rdCode", "rdName"];
			config.gridHeadTexts=["编码","名称"];
			config.typeName="出库类别查询";
			config.baseCondition = {'rdFlag':"2"};
			config.widths=[1,2];
			config.callback=callback;
			var win:SimpleDictWin=SimpleDictWin(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), SimpleDictWin));
			win.height=340;
			win.width=500;
			win.dictWinConfig=config;
			if (x == -1)
			{
				PopUpManager.centerPopUp(win);
			}
			else
			{
				win.x=x;
				win.y=y;
			}
		}
		
		/**
		 * 显示临床科室字典
		 * */
		public static function showDeptDict(callback:Function,x:int=-1, y:int=-1):void
		{
//			AppInfo.currentUserInfo=new SysUser()
//			AppInfo.currentUserInfo.inputCode="ddd"
			var config:SimpleDictWinConfig=new SimpleDictWinConfig();
//			config.destination='baseToolImpl';
			config.destination='commMaterialDictImpl';
			config.method="findByInputCodeExt";
			config.entityClassName="cn.superion.center.deptPerson.entity.CdDeptDict";
			config.serverOrderField="deptCode";
			
			config.gridDataFields=["deptCode", "deptName"];
			config.gridHeadTexts=["部门编码", "部门名称"];
			config.gridDataQueryOption=[{label: '拼音简码', field: 'phoInputCode'}, {label: '五笔简码', field: 'fiveInputCode'}];
			config.typeName="科室";
//			config.comboxData=[{label:'全院',data:'321201'},{label:'南院',data:'32120101'},{label:'北院',data:'32120102'}]
			
			if(isAllUnitsDict)
			{
				config.comboxData = SYS_UNITS.toArray();
				config.comboxLableField="unitsSimpleName"
				config.comboxFormItemLable="单位"
			}
//			config.baseCondition={deptSign: '1'};
			
			config.widths=[1, 3];
			config.callback=callback;
			
			var win:SimpleDictWin=SimpleDictWin(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), SimpleDictWin, true));
			win.height=340;
			win.width=726;
			win.dictWinConfig=config;
			if (x == -1)
			{
				PopUpManager.centerPopUp(win);
			}
			else
			{
				win.x=x;
				win.y=y;
			}
		}
		
		/**
		 * 显示高值耗材类物资字典
		 * */
		public static function showMaterialValueDict(callback:Function, x:int=-1, y:int=-1):void
		{
			var config:SimpleDictWinConfig=new SimpleDictWinConfig();
			config.destination='deptReceiveValueImpl';
			config.method="findValueMaterialDict";
			
			config.gridDataFields=["materialCode", "materialName", "materialSpec", "materialUnits", "factoryName"];
			config.gridHeadTexts=["物资编码", "物资名称", "规格型号", "单位", "生产厂家"];
			config.gridDataQueryOption=[{label: '拼音简码', field: 'phoInputCode'}, {label: '五笔简码', field: 'fiveInputCode'}];
			config.typeName="高值耗材类物资";
			config.baseCondition={'highValueSign':"1"}
			config.widths=[1.5, 4, 3, 1, 4];
			config.callback=callback;
			var win:SimpleDictWin=SimpleDictWin(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), SimpleDictWin, true));
			win.height=340;
			win.width=726;
			win.dictWinConfig=config;
			if (x == -1)
			{
				PopUpManager.centerPopUp(win);
			}
			else
			{
				win.x=x;
				win.y=y;
			}
		}
		
		
		/**
		 * 显示供应单位字典
		 * */
		public static function showProviderDict(callback:Function,x:int=-1, y:int=-1,fstrChargeDept:String=null,fstrProviderClass:String=null):void
		{
			var config:SimpleDictWinConfig=new SimpleDictWinConfig();
			config.baseCondition={providerChargeDept:fstrChargeDept,providerClass:fstrProviderClass}
			config.destination='commMaterialDictImpl';
			config.method="findByInputCodeExt";
			config.serverOrderField="providerCode";
			config.entityClassName="cn.superion.center.provider.entity.CdProvider";
			
			config.gridDataFields=["providerCode", "providerName"];
			config.gridHeadTexts=["单位编码", "单位名称"];
			config.gridDataQueryOption=[{label: '拼音简码', field: 'phoInputCode'}, {label: '五笔简码', field: 'fiveInputCode'}];
			config.typeName="往来单位";
			config.widths=[1, 4];
			
			if(isAllUnitsDict)
			{
				config.comboxData = SYS_UNITS.toArray();
				config.comboxLableField="unitsSimpleName"
				config.comboxFormItemLable="单位";
			}
			
			
			config.callback=callback;
			
			var win:SimpleDictWin=SimpleDictWin(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), SimpleDictWin, true));
			win.height=340;
			win.width=726;
			win.dictWinConfig=config;
			if (x == -1)
			{
				PopUpManager.centerPopUp(win);
			}
			else
			{
				win.x=x;
				win.y=y;
			}
		}
		
		/**
		 * 显示医生档案字典
		 * */
		public static function showDoctorDict(callback:Function, x:int=-1, y:int=-1):void
		{
			var config:SimpleDictWinConfig=new SimpleDictWinConfig();
			config.destination='commMaterialDictImpl';
			config.method="findByInputCodeExt";
			config.entityClassName="cn.superion.center.deptPerson.entity.CdPersonDict";
			config.serverOrderField="personCode";
			
			config.gridDataFields=["personCode", "name"];
			config.gridHeadTexts=["医生编号", "医生姓名"];
			config.gridDataQueryOption=[{label: '拼音简码', field: 'phoInputCode'}, {label: '五笔简码', field: 'fiveInputCode'}];
			config.typeName="医生档案";
			
			if(isAllUnitsDict)
			{
				config.comboxData = SYS_UNITS.toArray();
				config.comboxLableField="unitsSimpleName"
				config.comboxFormItemLable="单位";
			}
			config.widths=[1, 3];
			config.callback=callback;
			
			var win:SimpleDictWin=SimpleDictWin(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), SimpleDictWin, true));
			win.height=340;
			win.width=726;
			win.dictWinConfig=config;
			if (x == -1)
			{
				PopUpManager.centerPopUp(win);
			}
			else
			{
				win.x=x;
				win.y=y;
			}
		}
		
		/**
		 * 显示诊疗组字典
		 * */
		public static function showDeptGroupDict(callback:Function, x:int=-1, y:int=-1):void
		{
			var config:SimpleDictWinConfig=new SimpleDictWinConfig();
			config.destination='commMaterialDictImpl';
			config.method="findByInputCodeExt";
			config.entityClassName="cn.superion.center.deptPerson.entity.CdDeptDict";
			config.serverOrderField="deptCode";
			
			config.gridDataFields=["deptCode", "deptName"];
			config.gridHeadTexts=["诊疗组编码", "诊疗组名称"];
			config.gridDataQueryOption=[{label: '拼音简码', field: 'phoInputCode'}, {label: '五笔简码', field: 'fiveInputCode'}];
			config.typeName="诊疗组";
			config.baseCondition={groupSign: '1'};
			
			if(isAllUnitsDict)
			{
				config.comboxData = SYS_UNITS.toArray();
				config.comboxLableField="unitsSimpleName"
				config.comboxFormItemLable="单位";
			}
			
			config.widths=[1, 3];
			config.callback=callback;
			
			var win:SimpleDictWin=SimpleDictWin(PopUpManager.createPopUp(DisplayObject(FlexGlobals.topLevelApplication), SimpleDictWin, true));
			win.height=340;
			win.width=726;
			win.dictWinConfig=config;
			if (x == -1)
			{
				PopUpManager.centerPopUp(win);
			}
			else
			{
				win.x=x;
				win.y=y;
			}
		}
		
		public static function getAdvanceDictList():void
		{
			var ro:RemoteObject=RemoteUtil.getRemoteObject('materialCommonDictImpl', function(rev:Object):void
			{
				fillAdvanceDict(rev.data[0]);
			})
			ro.findAdvanceDict();
		}
		
		private static function fillAdvanceDict(data:Object):void
		{
			for (var field:String in data)
			{
				BaseDict[field + 'Dict']=data[field];
			}
		}
	}
}