package com.greencardigan.tc4;

import org.achartengine.ChartFactory;
import org.achartengine.GraphicalView;
import org.achartengine.model.XYMultipleSeriesDataset;
import org.achartengine.model.XYSeries;
import org.achartengine.renderer.XYMultipleSeriesRenderer;
import org.achartengine.renderer.XYSeriesRenderer;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Paint.Align;

public class LineGraph {

	private GraphicalView view;
	
	public XYSeries dataset1 = new XYSeries("Bean Temp"); 
	public XYSeries dataset2 = new XYSeries("Environmental Temp"); 
	private XYMultipleSeriesDataset mDataset = new XYMultipleSeriesDataset();
	
	private XYSeriesRenderer renderer1 = new XYSeriesRenderer(); // This will be used to customize line 1
	private XYSeriesRenderer renderer2 = new XYSeriesRenderer(); // This will be used to customize line 1

	public static XYMultipleSeriesRenderer mRenderer = new XYMultipleSeriesRenderer(); // Holds a collection of XYSeriesRenderer and customizes the graph
	
	public LineGraph()
	{
		// Add datasets to multiple dataset
		mDataset.addSeries(dataset1);
		mDataset.addSeries(dataset2);
		
		// Customization time for line 1!
		renderer1.setColor(Color.BLUE);
		//renderer.setPointStyle(PointStyle.SQUARE);
		//renderer.setFillPoints(true);
		renderer1.setLineWidth(8);
		
		// Customization time for line 2!
		renderer2.setColor(Color.RED);
		//renderer.setPointStyle(PointStyle.SQUARE);
		//renderer.setFillPoints(true);
		renderer2.setLineWidth(8);
		
		// Enable Zoom
		//mRenderer.setZoomButtonsVisible(true);
		mRenderer.setXTitle("Time");
		mRenderer.setYTitle("Temp");
		
		mRenderer.setAxisTitleTextSize(20);
		mRenderer.setLabelsTextSize(20);
		//mRenderer.setLegendTextSize(30);
		mRenderer.setShowLegend(false);
		mRenderer.setYLabelsAlign(Align.LEFT);
				
		// Add renderers to multiple renderer
		mRenderer.addSeriesRenderer(renderer1);	
		mRenderer.addSeriesRenderer(renderer2);	
	}
	
	public GraphicalView getView(Context context) 
	{
		view =  ChartFactory.getLineChartView(context, mDataset, mRenderer);
		return view;
	}
	
	public void addNewPoints1(Point p)
	{
		dataset1.add(p.getX(), p.getY());
	}
	
	public void addNewPoints2(Point p)
	{
		dataset2.add(p.getX(), p.getY());
	}
	
	public static void setMaxX(int x)
	{
		mRenderer.setXAxisMax(x);
	}
	
	public static void setMinX(int x)
	{
		mRenderer.setXAxisMin(x);
	}
	
	public static void setMaxY(int x)
	{
		mRenderer.setYAxisMax(x);
	}
}
