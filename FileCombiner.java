package edu.cmu.isri.wbt.hackthegrid;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.OutputStreamWriter;

public class FileCombiner {
	public static final String FILENAME_TABLE_ROW_HEADERS = "rownum,filename";
	private static final String EXPECTED_HEADERS = "\"siteid\",\"meterid\",\"dttm\",\"demand_kWh\"";
	private static final String WRITE_HEADERS = EXPECTED_HEADERS;//"\"meterid\",\"dttm\",\"demand_kWh\"";
	
	public FileCombiner(String inDir, String outFile) {
		//Not recursive.
		int limitleft = 260;
		int filesRead = 0;
		BufferedReader reader;
		BufferedWriter writer;
		try {
		writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(outFile), "UTF8"));
		writer.write(WRITE_HEADERS+"\r\n");
		System.out.println("Consolidating files from "+inDir+" into "+outFile+".");
		final File folder = new File(inDir) ;
	    for (final File fileEntry : folder.listFiles()) {
	    	 if (fileEntry.isFile()) { //subdirs IGNORED
	    		 filesRead++;
	    		 
	             try {
					reader = new BufferedReader(new FileReader(fileEntry));
					String line = reader.readLine();
					int linesOfData = 0;
					boolean setFirstTimestamp = false;
					String firstTimestamp = "";
					String[] lineElems;
					int meternum = 1;
					if(!line.equals(EXPECTED_HEADERS)) {
						System.out.println("Unexpected headers in file: "+fileEntry.getName());
					} else {
						while((line = reader.readLine()) != null) {
							//System.out.println(line);								
							if (!line.trim().isEmpty()) {
								lineElems = line.split(",");	
								if(!setFirstTimestamp) {
									firstTimestamp = lineElems[2];
									//System.out.println("First timestamp: "+firstTimestamp);
									setFirstTimestamp = true;
								} else if(firstTimestamp.equals(lineElems[2])) {
									//System.out.println("Found another meter!");
									meternum++;
								}
								
								
								writer.write(assembleLine(lineElems,meternum)+"\r\n");
								linesOfData++;
							}																					
						} 
					}
		    		 System.out.println("Copied "+fileEntry.getName()+" into consolidated file; read "+linesOfData+" lines ("+meternum+" meters) of data.");
					reader.close();
				} catch (IOException e) {
		            System.err.println("Error reading "+fileEntry.getName()+": "+e);
					e.printStackTrace();
				}
	             if (limitleft>1) {
	            	 limitleft--;
	             } else {
	            	 break;
	             }	             
	    	 }
	     }
		writer.close();
		} catch(IOException e) {
            System.err.println("Error writing file: "+e);
			e.printStackTrace();
		}
		System.out.println("Copied "+filesRead+" files into one.");
	     if(limitleft>1)
	    	 System.out.println("Finished with quota to spare.");
	     else {
	    	 System.out.println("Reached max document count and stopped.  Increase my processing limit to see more.");
	     }		            
	}	
	private String assembleLine(String[] elems, int elem1) {
		String retval= elems[0]+","+elem1; 
		/* Was trying to consolidate meter number into site ID; abandoned for easier metadata matching.
		if(elems[0].charAt(elems[0].length()-1) == '"') {
			retval = elems[0].substring(0,elems[0].length()-1)+"-"+elem1+'"';
		} else {
			retval = elems[0]+"-"+elem1;
		}
		*/
		for (int i=2; i<elems.length;i++) {
			retval+= ","+elems[i];
		}	
		return retval;
	}
}
