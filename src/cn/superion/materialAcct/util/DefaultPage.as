package cn.superion.materialAcct.util
{
	import cn.superion.base.components.controls.SuperDataGrid;
	import cn.superion.base.util.LoadModuleUtil;

	import mx.collections.ArrayCollection;
	import mx.controls.DataGrid;
	import mx.core.FlexGlobals;
	import mx.modules.ModuleLoader;

	public class DefaultPage
	{
		public function DefaultPage()
		{
		}

		//回到缺省主页面，供各分模块中的返回调用
		public static function gotoDefaultPage():void
		{
			var url:String='cn/superion/materialAcct/main/view/ModMainRight.swf';
			LoadModuleUtil.loadCurrentModule(ModuleLoader(FlexGlobals.topLevelApplication.mainWin.mainFrame), url, FlexGlobals.topLevelApplication.mainWin.modPanel);
		}

		public static function removeItemFromGrid(fgrid:DataGrid):void
		{
			var laryDatas:ArrayCollection=fgrid.dataProvider as ArrayCollection
			var lintSelIndex:int=fgrid.selectedIndex
			if (fgrid is SuperDataGrid)
			{
				laryDatas=SuperDataGrid(fgrid).getRawDataProvider() as ArrayCollection;
			}
			if (lintSelIndex >= 0 && laryDatas.length > 0)
			{
				laryDatas.removeItemAt(lintSelIndex)
			}
			fgrid.selectedIndex=lintSelIndex
		}
		
		//打印报表高度
		public static var ReceiveReportPrintHeight:String;
		public static var DeliverReportPrintHeight:String;

	}
}