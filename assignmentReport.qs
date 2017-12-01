/*
 -also check in peaklist for 13C assignemnt... and do not list if not found in peaklist or multiplet
 */
/******************************************************************************************************
 Generate .nmredata.sdf from Mnova 11
 by Damien Jeannerat, University of Geneva
 http://nmredata.org
 Starting program: assignmenetReport.qs for Mnova V11.0.1-17801
 *****************************************************************************************************/

/*globals Str, Molecule, Application, NMRAssignments, NMRSpectrum, settings, print, MessageBox, MnUi, FileDialog, Dir, File, TextStream, AssignmentReporter*/
/*jslint plusplus: true, indent: 4*/


function assignmentReport() {
    'use strict';
    var mol, assign, spectra, foundMulti, specIndex, spectrum, multi, standardReporter, correlationsReporter,
    diag, drawnItems, tableText, pageItem, i, standardTable, correlationsTable, table, cols, j, width,
    addNumberOfNuclides, addMultiplicity, parameters, correlationsTableStart, assignmentsArray, format,
    lines = 25,
    dw = Application.mainWindow.activeDocument,
    clipBoardKey = "Correlation Reporter/ClipBoard",
    correlations2DKey  = "Correlation Reporter/2D Correlations",
    orderKey = "Correlation Reporter/Order by shift",
    decimalsForProtonKey = "Correlation Reporter/Number of decimals for proton",
    decimalsForCarbonKey = "Correlation Reporter/Number of decimals for carbon and x-nuclei",
    showShiftKey = "Correlation Reporter/Show Shift",
    includeMultiplicityKey = "Correlation Reporter/Include Multiplicity",
    addNumberOfNuclidesKey = "Correlation Reporter/Add number of nuclides",
    exportToFileKey = "Correlation Reporter/Export to File",
    exportingFormatKey = "Correlation Reporter/Exporting Format",
    dropLinesWithoutCorrelationKey = "Correlation Reporter/Drop Lines Without Correlation",
    formatKey = "Correlation Reporter/Format",
    showDeltaForCarbonKey = "Correlation Reporter/Show Delta for carbon",
    reportTxtFileKey = "Correlation Reporter/Report Txt File",
    compound_number = 0,found_it,full_path,seppath,//dja dd
    path_elements,//add dj
    nmredata_level = 0, //add dj
    table_of_moleculeId=[],// add dj
    //  FileNameNmredata  = "out_export_nmredata.sdf.txt",
    file, stream, dataFile, outmol, //DJ add
    assignedMolecules,pageItem,spec,doc,page,jii,ipa,pageCount,itemCount,cn,nb_mol_id,known_mol,lop_id,shiftav,debug=0,//add dj
    reportHTMLFileKey = "Correlation Reporter/Report HTML File";
    function getActiveMolecule(aDocWin, aMolPlugin) {
        
        var mol = aMolPlugin.activeMolecule();
        if (mol.isValid()) {
            return mol;
        }
        
        if (aDocWin.itemCount("Molecule") === 1) {
            mol = new Molecule(aDocWin.item(0, "Molecule"));
            return mol;
        }
        return undefined;
    }
    
    function createHTMLReport(table, index, lines) {
        
        var i, j, output;
        
        function fillVoids(cell) {
            if (cell === undefined || cell === "") {
                return "-";
            }
            return cell;
        }
        
        
        output = "<font style=\"font-size: 8pt; font-family: Arial; color: black\">";
        output += "<html><head>";
        output += "<title>Correlations Table</title>";
        output += "</head><body>";
        output += '\n<table border="1" cellSpacing="0" cellPadding="4" width="100%">';
        output += '\n<tr style="background-color:silver">';
        
        
        for (i = 0; i < table[0].length; i++) {
            output += '<td><b>' + table[0][i] + '</b></td>';
        }
        output += '</tr>';
        
        if (index === undefined) {
            for (i =  1; i < table.length; i++) {
                output += '<tr>';
                for (j = 0; j < table[i].length; j++) {
                    output += '<td>' + fillVoids(table[i][j]) + '</td>';
                }
                output += '</tr>';
            }
        } else {
            
            if (index !== 0) {
                index = index * lines;
            }
            
            for (i = index + 1; (i < table.length && (i <= (index + lines))); i++) {
                output += '<tr>';
                for (j = 0; j < table[i].length; j++) {
                    output += '<td>' + fillVoids(table[i][j]) + '</td>';
                }
                output += '</tr>';
            }
        }
        output += '</table>';
        output += '</body></html>';
        
        return output;
    }
    
    
    
    function exportToFile(aFormat) {
        //	function exportToFile(parameters) {
        
        function formatHeader(aHeader) {
            var re, header = aHeader.toString();
            re = new RegExp("<(.*?)>|[&;]", 'g');
            header = header.replace(re, '');
            return header;
        }
        
        //   var i, file, stream, dataFile;
        
        //		if (aFormat) {
        //			dataFile = FileDialog.getSaveFileName("*.txt", "Save report in .sdf", settings.value(reportTxtFileKey, Dir.home()));
        //   dataFile = Dir.home() + "/Mnova_table_of_correlations.sdf.txt";
        //		} else {
        //			dataFile = FileDialog.getSaveFileName("*.html", "Save report in HTML format", settings.value(reportHTMLFileKey, Dir.home()));
        //		}
        
        /*    if (dataFile !== "") {
         
         file = new File(dataFile);
         
         //			if (aFormat) {
         settings.setValue(reportTxtFileKey, dataFile);
         //			} else {
         //				settings.setValue(reportHTMLFileKey, dataFile);
         //			}
         */
        /*        file.open(File.WriteOnly);
         stream = new TextStream(file);
         out_mol = mol.getMolfile();
         stream.writeln(out_mol);
         stream.writeln(">  <Mestre_correlation_table>");
         
         //			if (aFormat) {
         for (i = 0; i < table.length; i++) {
         ////				for (i = 1; i < table.length; i++) {
         if (i === 0) {
         stream.writeln(formatHeader(table[i].join("\t")));
         } else {
         stream.writeln(table[i].join("\t"));
         }
         stream.flush();
         }
         //			} else {
         //				tableText = createHTMLReport(table);
         //				stream.write(tableText);
         //				stream.flush();
         //			}
         stream.writeln("");
         stream.writeln("");
         stream.flush();
         file.close();
         }*/
    }
    
    
    
    function getCorrelationsArray() {
        
        return ["HSQC", "HMBC", "H2BC", "COSY", "NOESY", "TOCSY", "ROESY"];
    }
    
    function getCorrelationsDescriptions() {
        return [assign.realAssignedExp("HSQC"), "HMBC", "H2BC", assign.realAssignedExp("COSY"), assign.realAssignedExp("NOESY"), assign.realAssignedExp("TOCSY"), "ROESY"];
    }
    
    function getAssignmentsArray() {
        var headerArray = [];
        headerArray.push("No");
        
        if (!addNumberOfNuclides && !addMultiplicity) {
            headerArray.push("&delta; <sub>H</sub>");
        } else if (addNumberOfNuclides && !addMultiplicity) {
            headerArray.push("&delta; <sub>H</sub> (nH)");
        } else if (!addNumberOfNuclides && addMultiplicity) {
            headerArray.push("&delta; <sub>H</sub> (Mul, <i>J</i>)");
        } else if (addNumberOfNuclides && addMultiplicity) {
            headerArray.push("&delta; <sub>H</sub> (Mul, <i>J</i>, nH)");
        }
        return headerArray;
    }
    
    function getAssignmentsDescriptions() {
        var headerArray = [];
        headerArray.push("No");
        
        if (!addNumberOfNuclides && !addMultiplicity) {
            headerArray.push("&delta; <sub>H</sub>");
        } else if (addNumberOfNuclides && !addMultiplicity) {
            headerArray.push("&delta; <sub>H</sub> (nH)");
        } else if (!addNumberOfNuclides && addMultiplicity) {
            headerArray.push("&delta; <sub>H</sub> (Multiplicity, <i>J</i>)");
        } else if (addNumberOfNuclides && addMultiplicity) {
            headerArray.push("&delta; <sub>H</sub> (Multiplicity, <i>J</i>, nH)");
        }
        return headerArray;
    }
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    if (dw === undefined || Application.molecule === undefined) {
        return;
    }
    // dw.update();// does not work
    //Application.mainWindow.activeDocument.update();// does not work
    //%/%/%
    //  assignedMolecules = spectrum.getNMRAssignedMolecules();
    //  nmredata[looop_over_spectra] +=  " multi ID  " +  multi.id + " \n";
    
    
    // for (iii = 0; iii < assignedMolecules.length; ++iii) {
    //     pageItem = assignedMolecules[iii];
    //   mol = new Molecule(pageItem);
    // could loop over molecules issue
    //%/%/%
    //////////
    /// assignedMolecules,pageItem,spec,doc,page,jii,ipa,pageCount,itemCount,//add dj
    compound_number=-1;
    nb_mol_id=0;
    doc = Application.mainWindow.activeDocument;
    for (ipa = 0, pageCount = doc.pageCount(); ipa < pageCount; ipa++) {
        page = doc.page(ipa);
        for (jii = 0, itemCount = page.itemCount(); jii < itemCount; jii++) {
            spec = new NMRSpectrum(page.item(jii));
            if (spec.isValid()){
                
                //////////
                // compound_number = 0;
                assignedMolecules = spec.getNMRAssignedMolecules();
                for (cn = 0; cn < assignedMolecules.length; ++cn) {
                    pageItem = assignedMolecules[cn];
                    mol = new Molecule(pageItem);
                    
                    if (mol.isValid() && (mol !== undefined)){
                        known_mol=0;//false
                        for (lop_id = 0 ; lop_id < nb_mol_id; lop_id++){
                            if (mol.moleculeId === table_of_moleculeId[lop_id]){
                                known_mol=1;
                            }
                        }
                        if( known_mol === 0){
                            table_of_moleculeId[nb_mol_id]=mol.moleculeId;
                            nb_mol_id++;
                            compound_number++;
                            
                            
                            // before...
                            /*      compound_number = 1;
                             mol = getActiveMolecule(dw, Application.molecule);
                             if (mol === undefined || !mol.isValid()) {
                             MessageBox.critical("Invalid Molecule");
                             return;
                             }*/
                            
                            /// dj add to dump in file
                            //		dataFile = "/Volumes/san256/users_for_mac_system_macPro/jeannerat/Dropbox/mrc_working_group/work_on_NMR_record_generation/dj_mnova_generate_nmredata_sdf_file/toto.txt";
                            //	 dataFile = "/Users/djeanner/Dropbox/mrc_working_group/work_on_NMR_record_generation/dj_mnova_generate_nmredata_sdf_file/toto.txt";
                            // 	     	dataFile = FileDialog.getSaveFileName("*.txt", "Save report in .sdf", settings.value(reportTxtFileKey, Dir.home()));
                            parameters = {};
                            parameters.name_compound = "compound" + (compound_number+1);
                            
                            
                            // removed because not good if more than one manova file for the same dataset
                            /*  spectra = dw.itemCount("NMR Spectrum");
                             found_it = 1;
                             specIndex=0;
                             while ( specIndex < spectra && found_it) {//to list all
                             spectrum = new NMRSpectrum(dw.item(specIndex, "NMR Spectrum"));
                             
                             full_path=spectrum.getParam("Data File Name");
                             path_elements = full_path.split("/");
                             seppath="/";
                             if (path_elements.length < 3) {
                             path_elements = full_path.split("\\");
                             seppath="\\";
                             }
                             
                             // in case points to fid
                             if (path_elements[path_elements.length-1]==="fid" || path_elements[path_elements.length-1]==="ser"){
                             full_path="";
                             for (lo=0 ; lo <=path_elements.length-2 ; lo ++) {
                             full_path +=  path_elements[lo]  + seppath;
                             }
                             full_path += "pdata/1/2rr" ;
                             path_elements = full_path.split("/");seppath="/";
                             if (path_elements.length < 3) {
                             path_elements = full_path.split("\\");seppath="\\";
                             }
                             }
                             
                             parameters.name_compound= "/"  + path_elements[path_elements.length-5] ;
                             found_it=0;
                             specIndex++;
                             }*/
                            
                            
                            
                            
                            dataFile = Dir.home() + "/" + parameters.name_compound + ".nmredata.sdf";//HERE MAIN FILENAME
                            
                            if (dataFile !== "") {
                                file = new File(dataFile);
                                //settings.setValue(reportTxtFileKey, dataFile);
                                file.open(File.WriteOnly);
                                stream = new TextStream(file);
                                //stream.writeln(Dir.home());
                                
                                
                                parameters.dataFile=dataFile;
                                parameters.stream=stream;
                            }
                            
                            assign = new NMRAssignments(mol);
                            spectra = dw.itemCount("NMR Spectrum");
                            foundMulti = false;
                            specIndex = 0;
                            
                            while (!foundMulti  && specIndex < spectra) {
                                
                                spectrum = new NMRSpectrum(dw.item(specIndex, "NMR Spectrum"));
                                
                                if ((spectrum.nucleus() === "1H") && (spectrum.dimCount === 1)) {
                                    foundMulti = true;
                                    multi = spectrum.multiplets();
                                    
                                } else {
                                    specIndex++;
                                }
                            }
                            
                            
                            
                            if (!foundMulti) {
                                MessageBox.critical("Invalid Spectrum");// issue. not sure this is critical here..
                                return;
                            }
                            
                            out_mol = mol.getMolfile();
                            stream.write(out_mol);// bug reported by JMN Nov 9 replaced writeln with write to have one less end-of-line char in the file
                            
                            // output some comments
                            if (debug){
                                stream.writeln(">  <COMMENT_TO_DEL> ");
                                //stream.writeln(path_elements[path_elements.length-5]);
                                stream.writeln(";comments on the mol... ");
                                stream.writeln(";comments on the mol... ");
                                
                                stream.writeln(";molName :" + mol.molName);
                                
                                stream.writeln(";label :" + mol.label);
                                stream.writeln(";Description :" + mol.Description);
                                stream.writeln(";molecularFormula :" + mol.molecularFormula());
                                stream.writeln("");
                            }
                            ////////////////////////////////////////////////////
                            ////////////////////////////////////////////////////
                            ////////////////////////////////////////////////////
                            ////////////////////////////////////////////////////
                            ////////////////////////////////////////////////////
                            ////////////////////////////////////////////////////
                            ///
                            /// / just for solvent
                            spectra = dw.itemCount("NMR Spectrum");
                            found_it = 1;
                            while ( specIndex < spectra && found_it) {//to list all
                                spectrum = new NMRSpectrum(dw.item(specIndex, "NMR Spectrum"));
                                
                                stream.writeln(">  <NMREDATA_SOLVENT>\n" + spectrum.solvent + "\n");
                                
                                found_it=0;
                                
                                specIndex++;
                                
                            }
                            stream.writeln(">  <NMREDATA_LEVEL>\n" + nmredata_level + "\n");
                            
                            
                            ////////////////////////////////////////////////////
                            ////////////////////////////////////////////////////
                            ////////////////////////////////////////////////////
                            ////////////////////////////////////////////////////
                            ////////////////////////////////////////////////////
                            
                            
                            // output main molecule
                            //  aCount = aMolecule.atomCount,
                            //assignmentReport.qs:    atomLabel = aMolecule.atom(at).number;
                            //assignmentReport.qs:    element = aMolecule.atom(at).elementSymbol;
                            //   DBPlugin.qs:    dbItem.addField("Bonds", aMolecule.bondCount);
                            
                            stream.writeln(">  <NMREDATA_ASSIGNMENT>");
                            stream.flush();
                            
                            /*
                             diag = Application.loadUiFile("ricares:assignmentReport.ui");
                             
                             diag.widgets.gb2DCorrelations.checked = settings.value(correlations2DKey, true);
                             diag.widgets.sbDecimalsForProton.value = settings.value(decimalsForProtonKey, 2);
                             diag.widgets.sbDecimalsForCarbon.value = settings.value(decimalsForCarbonKey, 1);
                             diag.widgets.ckOrder.checked = settings.value(orderKey, true);
                             diag.widgets.gbShowDeltaForCarbon.checked = settings.value(showShiftKey, true);
                             diag.widgets.gbExportToFile.checked = settings.value(exportToFileKey, false);
                             diag.widgets.rbText.checked = settings.value(exportingFormatKey, true);
                             diag.widgets.rbHTML.checked = !diag.widgets.rbText.checked;
                             diag.widgets.ckClipBoard.checked = settings.value(clipBoardKey, true);
                             diag.widgets.ckIncludeMultiplicity.checked = settings.value(includeMultiplicityKey, false);
                             diag.widgets.ckAddNumberOfNuclides.checked = settings.value(addNumberOfNuclidesKey, false);
                             diag.widgets.ckDropLinesWithoutCorrelation.checked = settings.value(dropLinesWithoutCorrelationKey, false);
                             diag.widgets.ckShowDeltaForCarbon.checked = settings.value(showDeltaForCarbonKey, true);
                             format =  settings.value(formatKey, 1);
                             
                             
                             if (format === 0) {
                             diag.widgets.rbN.checked = true;
                             diag.widgets.rbDeltaN.checked = false;
                             diag.widgets.rbCnDelta.checked = false;
                             } else if (format === 1) {
                             diag.widgets.rbN.checked = false;
                             diag.widgets.rbDeltaN.checked = true;
                             diag.widgets.rbCnDelta.checked = false;
                             } else if (format === 2) {
                             diag.widgets.rbN.checked = false;
                             diag.widgets.rbDeltaN.checked = false;
                             diag.widgets.rbCnDelta.checked = true;
                             }
                             */
                            drawnItems = [];
                            
                            //	if (diag.exec()) {
                            
                            settings.setValue(correlations2DKey, true);// diag.widgets.gb2DCorrelations.checked);
                            settings.setValue(decimalsForProtonKey, 4);//diag.widgets.sbDecimalsForProton.value);
                            settings.setValue(decimalsForCarbonKey, 4);//diag.widgets.sbDecimalsForCarbon.value);
                            settings.setValue(orderKey, true);//diag.widgets.ckOrder.checked);
                            settings.setValue(showShiftKey, true);//diag.widgets.gbShowDeltaForCarbon.checked);
                            settings.setValue(exportToFileKey, true);//diag.widgets.gbExportToFile.checked);
                            settings.setValue(exportingFormatKey, true);//diag.widgets.rbText.checked);
                            settings.setValue(clipBoardKey, true);//diag.widgets.ckClipBoard.checked);
                            settings.setValue(includeMultiplicityKey, true);//diag.widgets.ckIncludeMultiplicity.checked);
                            settings.setValue(addNumberOfNuclidesKey, true);//diag.widgets.ckAddNumberOfNuclides.checked);
                            settings.setValue(dropLinesWithoutCorrelationKey, true);//diag.widgets.ckDropLinesWithoutCorrelation.checked);
                            settings.setValue(showDeltaForCarbonKey, true);//diag.widgets.ckShowDeltaForCarbon.checked);
                            
                            /*if (diag.widgets.rbN.checked) {
                             settings.setValue(formatKey, 0);
                             } else if (diag.widgets.rbDeltaN.checked) {
                             settings.setValue(formatKey, 1);
                             } else if (diag.widgets.rbCnDelta.checked) {
                             settings.setValue(formatKey, 2);
                             }*/
                            settings.setValue(formatKey, 0);
                            
                            addNumberOfNuclides = true;//diag.widgets.ckAddNumberOfNuclides.checked;
                            addMultiplicity =  true;//diag.widgets.ckIncludeMultiplicity.checked;
                            
                            assignmentsArray = getAssignmentsArray();
                            correlationsTableStart = assignmentsArray.length;
                            
                            standardReporter = new AssignmentReporter(assignmentsArray, "Main", getAssignmentsDescriptions(), "Correlation Reporter/H&C");
                            correlationsReporter = new AssignmentReporter(getCorrelationsArray(), "2D Correlations", getCorrelationsDescriptions(), "Correlation Reporter/2D");
                            
                            parameters.protonDecimals = 4;//diag.widgets.sbDecimalsForProton.value;
                            parameters.carbonDecimals = 4;//diag.widgets.sbDecimalsForCarbon.value;
                            parameters.assignmentObject = assign;
                            parameters.molecule = mol;
                            parameters.reporter = standardReporter;
                            parameters.multi = multi;
                            parameters.addNumberOfNuclides = addNumberOfNuclides;
                            parameters.addMultiplicity = addMultiplicity;
                            parameters.showDeltaForCarbon = true;//diag.widgets.ckShowDeltaForCarbon.checked;
                            // parameters.FileNameNmredata = FileNameNmredata;
                            
                            standardTable = AssignmentReporter.assignmentReport(parameters);
                            
                            //		if (diag.widgets.gb2DCorrelations.checked) {
                            parameters.reporter = correlationsReporter;
                            
                            //			if (diag.widgets.rbN.checked) {
                            //				parameters.format = 0;
                            //			} else if (diag.widgets.rbDeltaN.checked) {
                            //				parameters.format = 1;
                            //			} else if (diag.widgets.rbCnDelta.checked) {
                            parameters.format = 2;
                            //			}
                            
                            correlationsTable = AssignmentReporter.assignmentReportWithCorrelations(parameters);
                            //		}
                            
                            //		if (diag.widgets.gbShowDeltaForCarbon.checked) {
           //                 correlationsTableStart++;
                            //		}
                            
           //                 table = AssignmentReporter.getFinalTable(standardTable, correlationsTable);
                            
                            
                            //		if (diag.widgets.ckOrder.checked) {
           //                 table = AssignmentReporter.getOrderedTable(table);
                            //		}
                            
                            //		if (diag.widgets.ckShowDeltaForCarbon.checked) {
                            // back//			table = AssignmentReporter.removeVoidAssignmentsRows(table, standardReporter.xNuclidesIndex);
                            
                            //		} else {
          //                  table = AssignmentReporter.removeVoidAssignmentsRows(table, 1);
                            //		}
                            
                            //		if (diag.widgets.ckDropLinesWithoutCorrelation.checked && diag.widgets.gb2DCorrelations.checked) {
          //                  table = AssignmentReporter.removeVoidCorrelationsRows(table, standardReporter.xNuclidesIndex);
                            //		}
                            
                            //		table = AssignmentReporter.removeVoidColumns(table);
                            
                            
                            //		if (diag.widgets.ckClipBoard.checked) {
                            //
                            //			tableText = createHTMLReport(table);
                            //			pageItem = Application.draw.text(tableText, "Report Special", "Assignments Proton", true);
                            //			drawnItems.push(pageItem);
                            //
                            //			for (i = 1; i < drawnItems.length; i++) {
                            //				drawnItems[i].top = drawnItems[i - 1].top;
                            //				drawnItems[i].left = drawnItems[i - 1].right;
                            //			}
                            //			settings.setValue(clipBoardKey, true);
                            //			dw.setSelection(drawnItems);
                            //			Application.mainWindow.doAction("action_Edit_Copy");
                            //			Application.mainWindow.activeDocument.curPage().deleteItems(drawnItems);
                            //			dw.update();
                            //
                            //		} else {
                            //
                            //			cols = Math.ceil((table.length - 1) / lines);
                            //			for (i = 0; i < cols; i++) {
                            //
                            //				tableText = createHTMLReport(table, i, lines);
                            //				pageItem = Application.draw.text(tableText, "Report Special", "Assignments Proton", true);
                            //				drawnItems.push(pageItem);
                            //			}
                            //			for (j = 1; j < drawnItems.length; j++) {
                            ////				drawnItems[j].top = drawnItems[j - 1].top;
                            //				width = drawnItems[j].width;
                            //				drawnItems[j].right = drawnItems[j - 1].right + width;
                            //				drawnItems[j].left = drawnItems[j - 1].right;
                            //				drawnItems[j].update();
                            //				dw.update();
                            //			}
                            //			settings.setValue(clipBoardKey, false);
                            //			Application.mainWindow.activeDocument.curPage().update();
                            //		}
                            
                            
                            //		if (diag.widgets.gbExportToFile.checked) {
                            exportToFile(true);//exportToFile(diag.widgets.rbText.checked);
                            //		}
                            //	}
                            if (dataFile !== "") {
                                
                                stream.writeln("$$$$");
                                stream.flush();
                                file.close();
                            }
                        }
                    }
                }
            }
        }
    }
    dataFile = Dir.home() + "/mnova_process_done.txt";//HERE MAIN FILENAME
    if (dataFile !== "") {
        file = new File(dataFile);
        //settings.setValue(reportTxtFileKey, dataFile);
        file.open(File.WriteOnly);
        stream = new TextStream(file);
        stream.writeln("done");
        stream.flush();
        file.close();
    }
    dw.close();// close the document needed when running automatic scripts
    // write file flagging end of process
}



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function AssignmentReporter(aArray, aDescription, aCorrelationDesc) {
    'use strict';
    this.fCorrelations = aArray;
    this.fDescription = aDescription;
    this.fCorrelationsDescription = aCorrelationDesc;
    this.xNuclides = {"C": 2};
    this.xNuclidesIndex = 2;
    this.nucleids = {};
}

AssignmentReporter.prototype = {};


AssignmentReporter.getXNucleus = function (aElement, aAssignmentReporter) {
    'use strict';
    if (aAssignmentReporter.xNuclides[aElement] === undefined && aElement !== "H") {
        aAssignmentReporter.xNuclidesIndex++;
        aAssignmentReporter.xNuclides[aElement] = aAssignmentReporter.xNuclidesIndex;
    }
    return aAssignmentReporter.xNuclides[aElement];
    
};


AssignmentReporter.assignmentReport = function (parameters) {
    'use strict';
    
    var i, j, at, noEqHs, hIndex, atomLabel, atomRow, h, shift, hIsHeavyIndex, skip, shiftH, shiftH0, shiftH1, element, shifts, atomNH,
    aAssignmentObject = parameters.assignmentObject,
    aMolecule = parameters.molecule,
    aAssignmentReporter = parameters.reporter,
    aMultiplets = parameters.multi,
    aAddNumberOfNuclides = parameters.addNumberOfNuclides,
    aAddMultiplicity = parameters.addMultiplicity,
    aDecimals = parameters.protonDecimals,
    aDecimalsForCarbon = parameters.carbonDecimals,
    aCarbonAssignments = parameters.showDeltaForCarbon,
    mol=parameters.molecule,
    aCount = aMolecule.atomCount,
    tableRows = {},
    implicitH,//DJ add
    tagc = "", tagh = "",//DJ add
    lich = [], licc = [],//chemical shifts H and C
    lith = [], litc = [],//text associated to shifts H and C
    //   FileNameNmredata = parameters.FileNameNmredata,
    value_c_shift,//add DJ
    label = "",//add DJ
    counth = 0, countc = 0,//add dj
    stream = parameters.stream,//add dj
    dataFile = parameters.dataFile,//add dj
    ii , //add dj
    separ = ", ", nmredataLine,debug_assignment_tag = 0,//DJ add
    debug=0,
    headerRow = [];
    
    ///  here was ...
    
    
    if (aAssignmentReporter !== undefined) {
        for (i = 0; i < aAssignmentReporter.fCorrelations.length; i++) {
            headerRow.push(aAssignmentReporter.fCorrelationsDescription[i]);
        }
    }
    
    
    for (at = 1; at <= aCount; at++) {// loop over atoms…
        noEqHs = aAssignmentObject.notEqHs(at);
        skip = true;
        hIsHeavyIndex = false;
        atomLabel = aMolecule.atom(at).number;
        element = aMolecule.atom(at).elementSymbol;
        atomNH = aMolecule.atom(at).nHAll;
        /// dj add to dump in file
        if (dataFile !== "") {
            if (debug_assignment_tag){
                stream.write(";                                       Atom number : ");
                stream.write(at);
                stream.write(" (");
                stream.write(aMolecule.atom(at).elementSymbol);
                stream.writeln(")");
                //    stream.write(element);
                //   stream.writeln("");
            }
            stream.flush();
        }
        ///
        if (noEqHs.length === 0  && element !== "H") {
            
            atomRow = [];
            atomRow[0] = AssignmentReporter.atomIndexToString(atomLabel, at);
            shifts = [];
            atomRow[1] = "";
            nmredataLine="";
            if (aCarbonAssignments) {// parameters.showDeltaForCarbon
                shift =  aAssignmentObject.chemShiftArr(at);
                
                if (shift) {
                    if (shift[1]) {
                        shiftH0 = Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon);
                        shiftH1 = Number((shift[1].max + shift[1].min) / 2).toFixed(aDecimalsForCarbon);
                        atomRow[AssignmentReporter.getXNucleus(element, aAssignmentReporter)] = shiftH0 + "," + shiftH1;
                        // nmredataLine= element + AssignmentReporter.atomIndexToString(atomLabel, at) + separ + Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon) + separ +at + "      ;K1";
                        nmredataLine=   AssignmentReporter.atomIndexToString(atomLabel, at) + separ + Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon) + separ +at;// could add element
                        if (debug_assignment_tag){
                            nmredataLine += "           ;K1";
                        }
                    } else {
                        atomRow[AssignmentReporter.getXNucleus(element, aAssignmentReporter)] = Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon);
                        //  nmredataLine= element + AssignmentReporter.atomIndexToString(atomLabel, at) + separ + Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon) + separ + at + "      ;K2" ;
                        nmredataLine=  AssignmentReporter.atomIndexToString(atomLabel, at) + separ + Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon) + separ + at ;// could add element
                        if (debug_assignment_tag){
                            nmredataLine += "             ;K2";
                        }
                    }
                } else {
                    if (debug_assignment_tag){
                        
                        nmredataLine=";" +  AssignmentReporter.atomIndexToString(atomLabel, at) + separ + at + "delete this line atom type : " + element + "; K3 ";
                    }
                    if (element !== "C") {
                        atomRow[AssignmentReporter.getXNucleus(element, aAssignmentReporter)] = "";
                    } else {
                        atomRow[AssignmentReporter.getXNucleus(element, aAssignmentReporter)] = "-";
                    }
                }
            }
            tableRows[atomRow[0]] = atomRow;
            /// dj add to dump in file
            if (dataFile !== "") {
                if (debug_assignment_tag){
                    
                    stream.write(";                                       a:");
                    stream.writeln(atomRow);
                }
                
                if ( nmredataLine !== ""){
                    stream.writeln(nmredataLine);
                }
                stream.flush();
            }
            //
        } else {
            
            for (hIndex = 0; hIndex < noEqHs.length; hIndex++) {
                atomRow = [];
                atomRow[0] = AssignmentReporter.atomIndexToString(atomLabel, at);
                atomRow[1] = "";
                shifts = [];
                h = noEqHs[hIndex];
                if (h === 0) {
                    hIsHeavyIndex = true;//H not attached to any C
                }
                shift =  aAssignmentObject.chemShiftArr(at, h);
                
                nmredataLine= "";
                if (shift) {
                    if  (aMolecule.atom(at).elementSymbol !== "H") {
                        implicitH="H";
                    }else{
                        implicitH="";
                    }
                    if (noEqHs.length > 1) {
                        atomRow[0] = AssignmentReporter.atomIndexToString(atomLabel, at, h, true);
                        //   label="H" + AssignmentReporter.atomIndexToString(atomLabel, at, h, true); this is returning primes... we want a/b
                        label="H" + AssignmentReporter.atomIndexToString(atomLabel, at)
                        if (h==1){
                            label+="a";
                        }else{
                            label+="b";
                        }
                        nmredataLine = label + separ + Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon) + separ + implicitH + at ;
                        if (debug_assignment_tag){
                            nmredataLine +=  " ;check explicit H2 is OK ; L3";
                        }
                    } else if (noEqHs.length > 0) {
                        atomRow[0] = AssignmentReporter.atomIndexToString(atomLabel, at, h, false);
                        //  label=AssignmentReporter.atomIndexToString(atomLabel, at, h, false);// this is returning primies...
                        label="H" + AssignmentReporter.atomIndexToString(atomLabel, at) ;
                        //					nmredataLine = nmredataLine + "\n" + label + separ + Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon) + separ + "H" + at + " ;check explicit H is OK ; L2";
                        
                        nmredataLine = label + separ + Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon) + separ + implicitH + at ;
                        if (debug_assignment_tag){
                            nmredataLine +=  " ;check explicit H is OK ; L2 element:" + aMolecule.atom(at).elementSymbol + " expli: " + implicitH;
                            
                        }
                    }
                    skip = false;
                    
                    if (shift[1]) {
                        shiftH0 = Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimals);
                        shiftH1 = Number((shift[1].max + shift[1].min) / 2).toFixed(aDecimals);
                        shifts.push(shiftH0);
                        shifts.push(shiftH1);
                        
                    } else {
                        shiftH = Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimals);
                        shifts.push(shiftH);
                    }
                    
                    if (aAssignmentReporter.nucleids[atomRow[0] + "_" + shift]) {
                        aAssignmentReporter.nucleids[atomRow[0] + "_" + shift]++;
                        
                    } else {
                        if (noEqHs.length > 1) {
                            aAssignmentReporter.nucleids[atomRow[0] + "_" + shift] = 1;
                        } else {
                            if (shift.length > 1 || hIsHeavyIndex) {
                                aAssignmentReporter.nucleids[atomRow[0] + "_" + shift] = 1;
                            } else {
                                aAssignmentReporter.nucleids[atomRow[0] + "_" + shift] = atomNH;
                            }
                        }
                    }
                    /*  stream.write("TEE>>");stream.writeln(atomRow[0]);
                     stream.write("TAA>>");stream.writeln(shift);
                     stream.write("TAA1>");stream.writeln(shift[1]);
                     stream.write("TAA2>");stream.writeln(shift[2]);*/
                    
                    atomNH = aAssignmentReporter.nucleids[atomRow[0] + "_" + shift];
                    atomRow[1] = AssignmentReporter.findInformation(aDecimals, aMultiplets, shifts, atomNH, aAddNumberOfNuclides, aAddMultiplicity, label);
                    lith[counth]= AssignmentReporter.findInformation(aDecimals, aMultiplets, shifts, atomNH, aAddNumberOfNuclides, aAddMultiplicity, label);
                    lich[counth]= shift;
                    counth++;
                    
                } else {
                    atomRow[1] = "-";
                }
                
                /// dj add to dump in file
                if (dataFile !== "") {
                    if (debug_assignment_tag){
                        
                        stream.write(";                                       b:");
                        stream.writeln(atomRow);
                    }
                    
                    if ( nmredataLine !== ""){
                        stream.writeln(nmredataLine);
                    }
                    stream.flush();
                }
                //
                
                if (aCarbonAssignments) {// parameters.showDeltaForCarbon
                    nmredataLine ="";
                    
                    shift =  aAssignmentObject.chemShiftArr(at);
                    if (!hIsHeavyIndex && shift && element !== "H") {
                        skip = false;
                        
                        if (shift[1]) {
                            shiftH0 = Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon);
                            shiftH1 = Number((shift[1].max + shift[1].min) / 2).toFixed(aDecimalsForCarbon);
                            atomRow[AssignmentReporter.getXNucleus(element, aAssignmentReporter)] = shiftH0 + "," + shiftH1;
                            // nmredataLine =                       element + AssignmentReporter.atomIndexToString(atomLabel, at) + separ + shiftH0 + separ +  at ;
                            nmredataLine =                      + AssignmentReporter.atomIndexToString(atomLabel, at) + separ + shiftH0 + separ +  at ;
                            if (debug_assignment_tag){
                                nmredataLine +=   ";  LC1";
                            }
                            // nmredataLine = nmredataLine + "\n" + element + AssignmentReporter.atomIndexToString(atomLabel, at) + separ + shiftH1 + separ +  at ;
                            nmredataLine = nmredataLine + "\n" + AssignmentReporter.atomIndexToString(atomLabel, at) + separ + shiftH1 + separ +  at ;
                            if (debug_assignment_tag){
                                nmredataLine += ";  LC2";
                            }
                        } else {
                            atomRow[AssignmentReporter.getXNucleus(element, aAssignmentReporter)] = Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon);
                            value_c_shift=Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon);
                            // nmredataLine = element + AssignmentReporter.atomIndexToString(atomLabel, at) + separ + value_c_shift + separ + at + "    ; LC min/max:" + shift[0].max + " " + shift[0].min;
                            nmredataLine = AssignmentReporter.atomIndexToString(atomLabel, at) + separ + value_c_shift + separ + at;
                            if (debug_assignment_tag){
                                nmredataLine += "    ; LC min/max:" + shift[0].max + " " + shift[0].min;
                            }
                            
                            litc[countc]= value_c_shift;
                            licc[countc]= (shift[0].max + shift[0].min) / 2;
                            countc++;
                        }
                        /// dj add to dump in file
                        if ( hIndex === 0 ) {// only write c with the first proton bound to it
                            if (dataFile !== "") {
                                if (debug_assignment_tag){
                                    
                                    stream.write(";                                       c:");
                                    stream.writeln(atomRow);
                                }
                                
                                stream.writeln(nmredataLine);
                                stream.flush();
                            }
                        }
                        //
                    } else {
                        atomRow[AssignmentReporter.getXNucleus(element, aAssignmentReporter)] = "-";
                    }
                }
                
                tableRows[atomRow[0]] = atomRow;
            }
            
        }
    }
    stream.writeln("");// end of asignmenet tag DJ put back Nov 23
    /// dj add to dump in file
    if (dataFile !== "") {
        if (debug){
            stream.writeln("");
            // stream.writeln("");
            stream.writeln(">  <DEBUG_1D_1H_NOTOK>");
            stream.writeln(";not satisfactory...");
            //	stream.write(lich[ii]); could be used to sort....
            for (ii = 0; ii < counth; ii++) {
                stream.writeln(lith[ii]);
            }
            counth=0;
            stream.writeln("");
            //  stream.writeln("");
            stream.writeln(">  <DEBUG_1D_13C_NOTOK>");
            stream.writeln(";not satisfactory...");
            //	stream.write(licc[ii]); could be used to sort....
            for (ii = 0; ii < countc; ii++) {
                stream.writeln(litc[ii]);
            }
            counth=0;
            stream.writeln("");
            //   stream.writeln("");
            stream.flush();
        }
        // file.close();
    }
    //////
    
    for (j in aAssignmentReporter.xNuclides) {
        if (aAssignmentReporter.xNuclides.hasOwnProperty(j)) {
            headerRow.push("&delta; <sub>" + j + "</sub>");
        }
    }
    tableRows.header = headerRow;
    return tableRows;
};

AssignmentReporter.assignmentReportWithCorrelations = function (parameters) {
    'use strict';
    
    var i, at, noEqHs, hIndex, atomRow, h, c, shift, atomLabel, element, correlations,
    aAssignmentObject = parameters.assignmentObject,
    aMolecule = parameters.molecule,
    aAssignmentReporter = parameters.reporter,
    aFormat = parameters.format,
    aProtonDecimals = parameters.protonDecimals,
    aCarbonDecimals = parameters.carbonDecimals,
    correlationsArray = [],
    aCount = aMolecule.atomCount,j,
    tableRows = {},
    iii,pageItem, mol,
    assignString = "",
    nmrAssignObject,
    assignedMolecules,lll,//add dj
    tmpString = "",
    file,dataFile,stream,
    //  FileNameNmredata = parameters.FileNameNmredata,
    headerRow = [],
    dw = Application.mainWindow.activeDocument,lo,seppath,item_position=[],//dj add
    type,//add dj
    dataFile=parameters.dataFile,looop_over_spectra,//add dj
    stream=parameters.stream,root_path,rel_path,//add dj
    //   spectrum,//add dj
    test_type,path_elements,full_path,multi,lab,//add dj
    spectra,spectrum,specIndex,found_it,found_sih,ii,ma,j,ama,apa,noEqHs,keep_type,full_path_orig,cur_spec_atom,found_one,tmpll,labArray = [],peaklist,//add dj
    separ = ", ",smallest_cs,
    position_of_smallest_diff,debug=0,max_delta_chemshift_for_peak_to_be_assigned_to_chemical_shift = 0.05,conn,tmpi,tmparr = [],chem_shift,
    // emptynmr = [],
    nmredata = [];
    nmredata_header = [];
    
    
    function sortFunctionForFloats(a, b) {
        return parseFloat(a) - parseFloat(b);
    }
    
    tableRows.header = headerRow;

    if (aAssignmentReporter !== undefined) {
        stream.flush();
        //initialize output
        spectra = dw.itemCount("NMR Spectrum");
        specIndex=0;
        while ( specIndex < spectra ) {//to list all
            nmredata[specIndex+1] = "";
            nmredata_header[specIndex+1] = "";
            
            looop_over_spectra=specIndex+1;
            
            spectrum = new NMRSpectrum(dw.item(specIndex, "NMR Spectrum"));
            keep_type="na;Type was not identified" + spectrum.experimentType;
            
            for (i = 0; i < aAssignmentReporter.fCorrelations.length; i++) {
                headerRow.push(aAssignmentReporter.fCorrelationsDescription[i]);
                //  emptynmr[i] = true;
                type= aAssignmentReporter.fCorrelationsDescription[i];
                // specIndex=0;
                test_type= "2D-" + type;
                // loop over all spectra
                //   spectra = dw.itemCount("NMR Spectrum");
                // found_it = 1;
                // while ( specIndex < spectra && found_it) {//to list all
                //   while ( specIndex < spectra ) {//to list all
                //      spectrum = new NMRSpectrum(dw.item(specIndex, "NMR Spectrum"));
                if ((spectrum.experimentType === test_type))  {
                    item_position[i]=specIndex+1;
                    keep_type=type;
                }
                //      specIndex++;
                //  }
            }
            //
            cur_spec_atom="";
            label="";

            if (spectrum.dimCount === 1) {
                label = ">  <NMREDATA_1D_" +  spectrum.nucleus(1) + "";
                cur_spec_atom=spectrum.nucleus(1);
                cur_spec_atom=cur_spec_atom.replace(/[0-9]/g,"");// reploaces "13C" in to "C" - removed the numbers... convert isotope into element name
            }
            // the following lines apear at two places in the program... if change... change both...
            
            if (keep_type === "HSQC") { label = ">  <NMREDATA_2D_" +  spectrum.nucleus(1) + "_1J_" + spectrum.nucleus(2)  + ""; }
            if (keep_type === "HMBC") { label = ">  <NMREDATA_2D_13C_NJ_1H"; }
            if (keep_type === "H2BC") { label = ">  <NMREDATA_2D_13C_2J_1H"; }
            if (keep_type === "COSY") { label = ">  <NMREDATA_2D_" +  spectrum.nucleus(1) + "_NJ_" + spectrum.nucleus(1)  + ""; }
            if (keep_type === "NOESY") { label= ">  <NMREDATA_2D_" +  spectrum.nucleus(1) + "_D_" + spectrum.nucleus(1)  + ""; }
            if (keep_type === "TOCSY") { label= ">  <NMREDATA_2D_" +  spectrum.nucleus(1) + "_TJ_" + spectrum.nucleus(1)  + ""; }
            if (spectrum.dimCount === 2){
                if (label === ""){
                    // try to determine the type of experiment when not in the list of "official" Mnova type
                    if (spectrum.nucleus(2)===""){
                        lab= "_unidentified_homonuclear_2d_spectrum_" ;
                    }else{
                        lab = "_unidentified_heteronuclear_2d_spectrum_" ;
                        if ( spectrum.getParam("Pulse Sequence").find("hoesy",0) > -1){ lab="_D_";}// this is for hoesy see http://nmredata.org/wiki/NMReDATA_tag_format#Naming_tags_for_nD
                    }
                    if (spectrum.nucleus(2)===""){
                        label += ">  <NMREDATA_2D_" + spectrum.nucleus(1)  + lab + spectrum.nucleus(1)  + "";
                    }else{
                        label += ">  <NMREDATA_2D_" + spectrum.nucleus(1)  + lab + spectrum.nucleus(2)  + "";
                    }
                }
            }
            // add number to tag name when name already exist example : <NMREDATA_1D_1H> <NMREDATA_1D_1H.2> <NMREDATA_1D_1H.3>
            // count number of occurances of the current label in the alread existing tags.
            iii=1;
            for (at = 1; at < looop_over_spectra+1; at++) {// loop over spectra spectra
                lab=nmredata_header[at];
                if (lab !== ""){
                    if (lab.find(label,0) > -1){
                        iii++
                    }
                }
            }
            if (iii>1){
                label += "#" + iii ;// add number when more than one with the same name. The period is not allowed in sdf names. We replaced it with "#"
            }
            // dump tag name
            nmredata_header[looop_over_spectra] +=label+ ">\n";
            
            if ((spectrum.dimCount === 1) || (keep_type !== "")){
                
                nmredata_header[looop_over_spectra] += "Larmor=" + spectrum.frequency(spectrum.dimCount) + "\n";
                if (spectrum.dimCount === 2) { nmredata_header[looop_over_spectra] += "CorrType=" + keep_type + "\n"; }
                //   nmredata[looop_over_spectra] += "MnovaType=" + spectrum.experimentType + " ;optional\n";
                //   nmredata[looop_over_spectra] += "MnovaSpecCount=" + spectrum.specCount + " ;optional\n";
                //   nmredata[looop_over_spectra] += "OriginalFormat=" + spectrum.originalFormat + " ;optional in V1\n";
                nmredata_header[looop_over_spectra] += "Pulseprogram=" + spectrum.getParam("Pulse Sequence") + " ;optional in V1\n";
                //     nmredata[looop_over_spectra] += "Spectrum_Location_absolute=file:" + spectrum.getParam("Data File Name") + " ;optional (what is required is the file pointer relative to base of the NMR record)\n";
            }
            
            if (spectrum.dimCount === 1) {
                multi = spectrum.multiplets();
                
                //   nmredata[looop_over_spectra] +=  ";DEBUH category <" +  multi.category + ">\n";
                
                //   nmredata[looop_over_spectra] += "zzzzzzzzzzzzzzzzz" + multi.count + " ;optional what is required is relative to NMR record\n";
                //U      ii=0;
                
                //U      while (ii < multi.count) {
                // lith[counth]= AssignmentReporter.findInformation(aDecimals, aMultiplets, shifts, atomNH, aAddNumberOfNuclides, aAddMultiplicity, label);
                //lich[counth]= shift;
                
                
                //  assignedMolecules = spectrum.getNMRAssignedMolecules();
                //  nmredata[looop_over_spectra] +=  " multi ID  " +  multi.id + " \n";
                
                
                // for (iii = 0; iii < assignedMolecules.length; ++iii) {
                //     pageItem = assignedMolecules[iii];
                //   mol = new Molecule(pageItem);
                //  if (mol.isValid()) {
                //  nmrAssignObject = new NMRAssignments(aMolecule);
                // nmrAssignObject = aAssignmentObject;
                // ma=aAssignmentObject.multipletAssignment;
                //    for (j = 0; j < ma.length; ++j) {
                // nmredata[looop_over_spectra] +=  " nmrAssignObject   " +  aAssignmentObject + " \n";
                /* if (debug){
                 nmredata[looop_over_spectra] +=  ";aAssignmentObject:  NMRAssignment   <" +  aAssignmentObject.NMRAssignment + ">";
                 nmredata[looop_over_spectra] +=  " multipletAssignment:<" +  aAssignmentObject.multipletAssignment + ">";
                 nmredata[looop_over_spectra] +=  " peakAssignment<   " +  aAssignmentObject.peakAssignment + ">";
                 //  ama=  aAssignmentObject.multipletAssignment;
                 // apa=  aAssignmentObject.peakAssignment;
                 // nmredata[looop_over_spectra] +=  " nmrAssignObject.   " +  ama + ">";
                 //   nmredata[looop_over_spectra] +=  " nmrAssignObject.   " +  apa + ">";
                 nmredata[looop_over_spectra] +=  " notEqHs<." +  aAssignmentObject.notEqHs + ">\n";
                 }*/
                
                for (at = 1; at <= aCount; at++) {// loop over atoms…
                    
                    element = aMolecule.atom(at).elementSymbol;
                    //  if  ( (element === cur_spec_atom ) || (element === "H" )){
                    noEqHs = aAssignmentObject.notEqHs(at);
                    
                    /* skip = true;
                     hIsHeavyIndex = false;
                     atomLabel = aMolecule.atom(at).number;
                     element = aMolecule.atom(at).elementSymbol;
                     atomNH = aMolecule.atom(at).nHAll;
                     /// dj add to dump in file
                     if (dataFile !== "") {
                     stream.write(";                                        atom number : ");
                     stream.writeln(at);
                     stream.flush();
                     }
                     ///
                     if (noEqHs.length === 0  && element !== "H") {*/
                    atomNH = aMolecule.atom(at).nHAll;
                    hIsHeavyIndex = false;
                    /*  nmredata[looop_over_spectra] +=  "Testing  element from mol : "  ;
                     nmredata[looop_over_spectra] +=  element  ;
                     nmredata[looop_over_spectra] +=   " and element of current spetrum " ;
                     
                     nmredata[looop_over_spectra] += cur_spec_atom + "(isotope: " + spectrum.nucleus(1) + ") \n";//.toFixed(4);//DJ_DEBUG*/
                    
                    
                    if  (element === cur_spec_atom ) {
                        
                        //  nmredata[looop_over_spectra] +=at +  "  " + aMolecule.atom(at).elementSymbol ;//.toFixed(4);//DJ_DEBUG
                        //  nmredata[looop_over_spectra] +=  "<<" + aMolecule.atom(at).number + ">>";//.toFixed(4);//DJ_DEBUG
                        
                        //  nmredata[looop_over_spectra] +=  " " + aMolecule.atom(at).nHAll + "H \n";//.toFixed(4);//DJ_DEBUG
                        atomLabel = aMolecule.atom(at).number;
                        
                        // for heavy atom
                        lab=AssignmentReporter.atomIndexToString(atomLabel, at);
                        
                        
                        shift=-1234231234;
                        shift =  aAssignmentObject.chemShiftArr(at);
                        //  nmredata[looop_over_spectra] +=  "[i[" + lab + "]]";//.toFixed(4);//DJ_DEBUG
                        /* stream.writeln(nmredata[looop_over_spectra]);
                         stream.writeln("fsdadsafdafds");
                         stream.writeln("");
                         stream.writeln("");
                         stream.writeln("");
                         stream.writeln("");
                         stream.writeln("----------------------- for debugging---------------------------------");
                         stream.flush();
                         */
                        //if (shift[0]) {
                        
                        
                        
                        
                        
                        shifts=[];
                        if (shift) {
                            
                            if (shift[1]) {// most of this should be useless because this is the heavy atom...
                                if (shift[0].max === shift[0].min){
                                    shiftH0 = Number((shift[0].max + shift[0].min) / 2).toFixed(4);
                                }else{
                                    shiftH0 = Number(shift[0].max).toFixed(4) + "-" + Number(shift[0].min).toFixed(4);
                                }
                                if (shift[1].max === shift[1].min){
                                    shiftH1 = Number((shift[1].max + shift[1].min) / 2).toFixed(4);
                                }else{
                                    shiftH1 = Number(shift[1].max).toFixed(4) + "-" + Number(shift[1].min).toFixed(4);
                                }
                                shifts.push(shiftH0);
                                shifts.push(shiftH1);
                                
                            } else {
                                if (shift[0].max === shift[0].min){
                                    shiftH = Number((shift[0].max + shift[0].min) / 2).toFixed(4);
                                }else{
                                    shiftH = Number(shift[0].max).toFixed(4) + "-" + Number(shift[0].min).toFixed(4);
                                }
                                //shiftH = Number((shift[0].max + shift[0].min) / 2).toFixed(4);
                                shifts.push(shiftH);
                            }
                            
                            
                            
                            
                            mul=AssignmentReporter.findInformation(4, multi, shifts, atomNH, true, true, atomLabel) + "";
                            
                            
                            if (mul.find(",",0) > 0) {
                                nmredata[looop_over_spectra] +=  mul + "; found multiplet by chemical shift \n";
                            }else{
                                
                                /// here serach for multiplet assigned to this...
                                ii=0;
                                found_one=0;
                                while (ii < multi.count) {
                                    tmpll=multi.at(ii).name;
                                    labArray = tmpll.split(",");
                                    // labArray = labArray();
                                    for (loi=0 ; loi < labArray.length ; loi ++) {
                                        if (labArray[loi] === atomLabel) {
                                            found_one=1;
                                            nmredata[looop_over_spectra] +=   multi.at(ii).delta.toFixed(4) ;//DJ_DEBUG
                                            nmredata[looop_over_spectra] +=  separ + "S=" + multi.at(ii).category.toLowerCase() ;//DJ_DEBUG
                                            // nmredata[looop_over_spectra] +=  separ+ "Nwrong="  + multi.at(ii).nH ;//DJ_DEBUG
                                            conn=-1;tmpi=0;
                                            while (multi.at(ii).name.find("&",tmpi) > 0){
                                                tmpi=multi.at(ii).name.find("&",tmpi);
                                                tmpi++;
                                                conn++;
                                            }
                                            if (conn>0){
                                                nmredata[looop_over_spectra] += separ + "N=" +  conn;//UZ
                                            }
                                            nmredata[looop_over_spectra] +=  separ + "L="  + multi.at(ii).name.replace(/,/g,"&");//DJ_DEBUG
                                            nmredata[looop_over_spectra] +=  separ + "E="  + multi.at(ii).integralValue(1e3).toFixed(4);//DJ_DEBUG
                                            lll=multi.at(ii).jList();
                                            for (j = 0; j < lll.length; ++j) {
                                                if (j === 0){
                                                    nmredata[looop_over_spectra] +=  separ + "J=" ;//DJ_DEBUG
                                                }
                                                nmredata[looop_over_spectra] +=  lll.at(j).toFixed(2);//DJ_DEBUG
                                                if (j+1 !== lll.length){
                                                    nmredata[looop_over_spectra] +=  "," ;//DJ_DEBUG
                                                }
                                            }
                                            nmredata[looop_over_spectra] +=  "; found multiplet by label chem shifts differ by " + Number(mul- multi.at(ii).delta).toFixed(6) + " ppm\n";//DJ_DEBUG
                                            
                                        }
                                    }
                                    ii++;
                                }
                                
                                ///00//
                                /// here serach for peak assigned to this...
                                if (found_one === 0){ // if found no multiplet look for peak...
                                    peaklist=  spectrum.peaks();
                                    
                                    ii=0;
                                    found_one=0;
                                    smallest_cs=1e6;
                                    position_of_smallest_diff=-1;
                                    
                                    while (ii < peaklist.count) {
                                        tmpll=peaklist.at(ii);//peak.annotation
                                        if (tmpll.type === 0){  // this indicate assigned to molecule (not solvent or impuritiy... so considers it)
                                            if ( (tmpll.delta()-(shift[0].max*0.5+0.5*shift[0].min))*(tmpll.delta()-(shift[0].max*0.5+0.5*shift[0].min)) < smallest_cs*smallest_cs){
                                                smallest_cs=tmpll.delta()-(shift[0].max*0.5+0.5*shift[0].min) ;// take the square because don't know how to make abs....
                                                position_of_smallest_diff=ii;
                                            }
                                            
                                            /* if (at === 1){
                                             //  nmredata[looop_over_spectra] += ";DEB PEAKLIST1 " + ii + " " + peaklist.at(ii).annotation + " " + peaklist.at(ii).peak.delta + "\n" ;
                                             nmredata[looop_over_spectra] += ";DEB PEAKLISTi " + ii + " an:<" + tmpll.annotation + "> d <" + tmpll.delta().toFixed(4)  + ">";
                                             nmredata[looop_over_spectra] +=  " i <" + tmpll.intensity.toFixed(4)  + ">";
                                             nmredata[looop_over_spectra] +=  " E <" + tmpll.integral.toFixed(4)  + ">";
                                             
                                             nmredata[looop_over_spectra] +=  " 13Cmul <" + tmpll.c13Multiplicity  + ">";
                                             nmredata[looop_over_spectra] +=  " type <" + tmpll.type  + ">";
                                             nmredata[looop_over_spectra] +=  " typetostring() <" + tmpll.typeToString()  + ">";//peak.compoundLabel(spec.solvent)
                                             nmredata[looop_over_spectra] +=  " flagtostring() <" + tmpll.flagsToString()  + ">";//peak.compoundLabel(spec.solvent)
                                             nmredata[looop_over_spectra] +=  " compoundLabel() <" + tmpll.compoundLabel(spectrum.solvent)  + ">";
                                             nmredata[looop_over_spectra] +=  " kindToString() <" + tmpll.kindToString()  + ">";
                                             nmredata[looop_over_spectra] +=  " kurtosis <" + tmpll.kurtosis  + ">";
                                             //  nmredata[looop_over_spectra] +=  " area <" + tmpll.area  + ">";
                                             //  nmredata[looop_over_spectra] +=  " ion <" + tmpll.io  + ">";
                                             nmredata[looop_over_spectra] +=  " width <" + tmpll.width(0)  + ">";
                                             nmredata[looop_over_spectra] +=  "\n" ;
                                             }*/
                                        }
                                        ii++;
                                    }
                                    if ((position_of_smallest_diff !== -1) && (Number(smallest_cs*smallest_cs) < Number(max_delta_chemshift_for_peak_to_be_assigned_to_chemical_shift*max_delta_chemshift_for_peak_to_be_assigned_to_chemical_shift))) {
                                        
                                        found_one=1;
                                        
                                        tmpll=peaklist.at(position_of_smallest_diff);//peak.annotation
                                        /* if want to give the chemical shift of the assignement... we we want the true chemical shift of the peak...
                                         if (shift[0].max === shift[0].min){
                                         nmredata[looop_over_spectra] += Number((shift[0].max + shift[0].min) / 2).toFixed(4);
                                         }else{
                                         nmredata[looop_over_spectra] += Number(shift[0].max).toFixed(4) + "-" + Number(shift[0].min).toFixed(4);
                                         }*/
                                        nmredata[looop_over_spectra] += tmpll.delta().toFixed(4)  ;
                                        // nmredata[looop_over_spectra] += ";DAB PEAKLISTj " + tmpll + " an:<" + tmpll.annotation + "> d <" + tmpll.delta().toFixed(4)  + ">";
                                        nmredata[looop_over_spectra] += separ + "L=" + atomLabel
                                        if (tmpll.intensity !== 0){
                                            nmredata[looop_over_spectra] += separ + "I=" + tmpll.intensity.toFixed(4) ;
                                        }
                                        if (tmpll.integral !== 0){
                                            nmredata[looop_over_spectra] += separ + "E=" + tmpll.integral.toFixed(4)  ;
                                        }
                                        
                                        if (Number(tmpll.width(0)*spectrum.frequency(spectrum.dimCount)) > 0.005){
                                            nmredata[looop_over_spectra] += separ + "W=" + Number(tmpll.width(0)*spectrum.frequency(spectrum.dimCount)).toFixed(2)  ;
                                        }
                                        
                                        nmredata[looop_over_spectra] +=  ";errcs=" + smallest_cs.toFixed(6) + " ppm (This is how far this peak is from the assigned resonance)"  ;
                                        
                                        nmredata[looop_over_spectra] +=  "\n" ;
                                        if (debug){
                                            nmredata[looop_over_spectra] +=  " 13Cmul <" + tmpll.c13Multiplicity  + ">";
                                            nmredata[looop_over_spectra] +=  " flagtostring() <" + tmpll.flagsToString()  + ">";//peak.compoundLabel(spec.solvent)
                                            nmredata[looop_over_spectra] +=  " compoundLabel() <" + tmpll.compoundLabel(spectrum.solvent)  + ">";
                                            nmredata[looop_over_spectra] +=  " kindToString() <" + tmpll.kindToString()  + ">";
                                            nmredata[looop_over_spectra] +=  " kurtosis <" + tmpll.kurtosis  + ">";
                                            nmredata[looop_over_spectra] +=  " distance... <" + smallest_cs  + ">";
                                            nmredata[looop_over_spectra] += separ + "w=" + tmpll.width(0)  ;
                                            nmredata[looop_over_spectra] += separ + "v*larmor=" + tmpll.width(0)*spectrum.frequency(spectrum.dimCount)  ;
                                            nmredata[looop_over_spectra] +=  "\n" ;
                                        }
                                    }
                                }// too
                                //00//
                                if (found_one === 0){
                                    
                                    nmredata[looop_over_spectra] +=";nothing at " + mul + " ppm " ;
                                    if (atomLabel !== ""){
                                        nmredata[looop_over_spectra] += separ + "for signal " + atomLabel ;
                                    }
                                    nmredata[looop_over_spectra] += "; found 1) no multiplet at this EXACT chem shift or  label 2) no peak +/-" + max_delta_chemshift_for_peak_to_be_assigned_to_chemical_shift + " pmm in peak list";
                                    if (smallest_cs<10000){
                                        nmredata[looop_over_spectra] += " (smallest:" + smallest_cs.toFixed(6) + ")\n" ;
                                    }else{
                                        nmredata[looop_over_spectra] += "\n" ;
                                        
                                    }
                                    
                                    
                                }
                                /// end search....
                                
                                
                                
                            }
                            if (debug){
                                nmredata[looop_over_spectra] +=  "; --- " + mul + ">>;MX El.:" + element + " lab:<" + atomLabel + "> CS 0:" + shift[0].max.toFixed(4) + "-" + shift[0].min.toFixed(4) ;//.toFixed(4);//DJ_DEBUG
                                if (shift[1]) {//  this should be useless because this is the heavy atom...
                                    nmredata[looop_over_spectra] +=   "CS 1:" + shift[1].max.toFixed(4) + "-" + shift[1].min.toFixed(4) ;//.toFixed(4); .DJ_DEBUG
                                    
                                }
                                nmredata[looop_over_spectra] +=  "\n";
                                
                            }
                        }
                        
                        
                        
                        
                        
                    }
                    // nmredata[looop_over_spectra] +=  "qNumboer of H... " + noEqHs.length + "eleent:" + element + " \n";//.toFixed(4);//DJ_DEBUG
                    
                    if  ((noEqHs.length !== 0) &&  (cur_spec_atom === "H" )){
                        
                        // nmredata[looop_over_spectra] +=  " Numboer of H... " + noEqHs.length + "eleent:" + element + " \n";//.toFixed(4);//DJ_DEBUG
                        
                        // for H
                        for (hIndex = 0; hIndex < noEqHs.length; hIndex++) {
                            atomRow = [];
                            atomRow[0] = AssignmentReporter.atomIndexToString(atomLabel, at);
                            atomRow[1] = "";
                            shifts = [];
                            h = noEqHs[hIndex];
                            if (h === 0) {
                                hIsHeavyIndex = true;//H not attached to any C
                            }
                            shift =  aAssignmentObject.chemShiftArr(at, h);
                            //  nmredata[looop_over_spectra] +=  " shift  " + shift + " \n";//.toFixed(4);
                            
                            
                            if (shift) {//add label in first column
                                if (noEqHs.length > 1) {
                                    lab=AssignmentReporter.atomIndexToString(atomLabel, at, h, true);
                                    if (debug)   nmredata[looop_over_spectra] +=  "; > " + lab + " ";//DJ_DEBUG
                                    
                                    atomRow[0] = lab;
                                } else if (noEqHs.length > 0) {
                                    lab=AssignmentReporter.atomIndexToString(atomLabel, at, h, false);
                                    if (debug)    nmredata[looop_over_spectra] +=  ";>> " + lab + " ";//DJ_DEBUG
                                    
                                    atomRow[0] = lab;
                                }
                                label="H" + lab;
                                // was here             }
                                if (debug)      nmredata[looop_over_spectra] +=  " (label=" + lab + ") ";//DJ_DEBUG
                                
                                
                                
                                
                                if (debug)      nmredata[looop_over_spectra] +=  " (shift0=" + shift[0].min.toFixed(4) + " - " + shift[0].max.toFixed(4) +") ";//.toFixed(4);//DJ_DEBUG
                                if (shift[1]){
                                    if (debug)        nmredata[looop_over_spectra] +=  " (shift1=" + shift[1].min.toFixed(4) + " - " + shift[1].max.toFixed(4) + ") ";//.toFixed(4);//DJ_DEBUG
                                }
                                if (debug)    nmredata[looop_over_spectra] +=  " (atomRow[0]=" + atomRow[0] + ") ";//.toFixed(4);//DJ_DEBUG
                                
                                ////////
                                
                                if (aAssignmentReporter.nucleids[atomRow[0] + "_" + shift]) {
                                    aAssignmentReporter.nucleids[atomRow[0] + "_" + shift]++;
                                    
                                } else {
                                    if (noEqHs.length > 1) {
                                        aAssignmentReporter.nucleids[atomRow[0] + "_" + shift] = 1;
                                    } else {
                                        if (shift.length > 1 || hIsHeavyIndex) {
                                            aAssignmentReporter.nucleids[atomRow[0] + "_" + shift] = 1;
                                        } else {
                                            aAssignmentReporter.nucleids[atomRow[0] + "_" + shift] = atomNH;
                                        }
                                    }
                                }
                                ////////
                                
                                
                                
                                
                                
                                //   nmredata[looop_over_spectra] +=  " (atomNH=" + atomNH + ") ";//.toFixed(4);
                                
                                if (shift[1]) {
                                    if (shift[0].max === shift[0].min){
                                        shiftH0 = Number((shift[0].max + shift[0].min) / 2).toFixed(4);
                                    }else{
                                        shiftH0 = Number(shift[0].max).toFixed(4) + "-" + Number(shift[0].min).toFixed(4);
                                    }
                                    if (shift[1].max === shift[1].min){
                                        shiftH1 = Number((shift[1].max + shift[1].min) / 2).toFixed(4);
                                    }else{
                                        shiftH1 = Number(shift[1].max).toFixed(4) + "-" + Number(shift[1].min).toFixed(4);
                                    }
                                    shifts.push(shiftH0);
                                    shifts.push(shiftH1);
                                    
                                } else {
                                    if (shift[0].max === shift[0].min){
                                        shiftH = Number((shift[0].max + shift[0].min) / 2).toFixed(4);
                                    }else{
                                        shiftH = Number(shift[0].max).toFixed(4) + "-" + Number(shift[0].min).toFixed(4);
                                    }
                                    //shiftH = Number((shift[0].max + shift[0].min) / 2).toFixed(4);
                                    shifts.push(shiftH);
                                }
                                if (debug)      nmredata[looop_over_spectra] += "\n";//.toFixed(4);//DJ_DEBUG
                                
                                /*
                                 atomNH = aAssignmentReporter.nucleids[atomRow[0] + "_" + shift];
                                 mul="";
                                 mul=AssignmentReporter.findInformation(4, multi, shifts, atomNH, true, true, label);
                                 nmredata[looop_over_spectra] +=  " MH " + mul + " HAARE del\n";//.toFixed(4);//DJ_DEBUG
                                 */
                                atomLabel = aMolecule.atom(at).number;
                                if (noEqHs.length >1 ){
                                    if (h === 1){
                                        atomLabel += "a" ;// issue replace...
                                    }else{
                                        atomLabel += "b" ;// issue replace...
                                    }
                                }
                                atomNH = aMolecule.atom(at).nHAll;
                                mul=" ";
                                // not trusting this function...
                                //                                         mul=AssignmentReporter.findInformation(4, multi, shifts, atomNH, true, true, label);
                                
                                //
                                if (mul.find(",",0) <0){// no multiplet found}
                                    found_sih=0;
                                    //   nmredata[looop_over_spectra] += "; " +  mul + ";  no multiplet found for this H\n";//.toFixed(4);//DJ_DEBUG
                                    
                                    // determin chemical shift....
                                    if (noEqHs.length >2 ){// there is a problem here.... may not be correct if two NE protons...
                                        if (h === 1){
                                            chem_shift = Number((shift[0].max + shift[0].min) / 2);
                                            if (shift[0].max === shift[0].min){
                                                shiftH = Number((shift[0].max + shift[0].min) / 2).toFixed(4);
                                            }else{
                                                shiftH = Number(shift[0].max).toFixed(4) + "-" + Number(shift[0].min).toFixed(4);
                                            }
                                        }
                                        if (h === 2) {
                                            chem_shift = Number((shift[1].max + shift[1].min) / 2);
                                            if (shift[1].max === shift[1].min) {
                                                shiftH = Number((shift[1].max + shift[1].min) / 2);
                                            }else{
                                                shiftH = Number(shift[1].max).toFixed(4) + "-" + Number(shift[1].min).toFixed(4);
                                            }
                                        }
                                    }else{
                                        chem_shift = Number((shift[0].max + shift[0].min) / 2);
                                        if (shift[0].max === shift[0].min){
                                            shiftH = Number((shift[0].max + shift[0].min) / 2).toFixed(4);
                                        }else{
                                            shiftH = Number(shift[0].max).toFixed(4) + "-" + Number(shift[0].min).toFixed(4);
                                        }
                                    }
                                    /// here serach for H multiplet assigned to lablel
                                    ii=0;
                                    while ((ii < multi.count) && (found_sih === 0)) {
                                        //   tmpll=multi.at(ii).name;
                                        //  tmpll=multi.at(ii).id;
                                        tmpll=aAssignmentObject.multipletAssignment(multi.at(ii).id);
                                        labArray = tmpll.split(",");
                                        // labArray = labArray();
                                        for (loi=0 ; loi < labArray.length ; loi ++) {
                                            if (labArray[loi] !== ""){
                                                //   nmredata[looop_over_spectra] += ";;; Testing " + labArray[loi] + " === " + atomLabel + "\n";
                                                
                                                //   if (labArray[loi] === atomLabel) {
                                                if (labArray[loi] === atomLabel) {
                                                    found_sih=1;
                                                    nmredata[looop_over_spectra] +=   multi.at(ii).delta.toFixed(4) ;//DJ_DEBUG
                                                    nmredata[looop_over_spectra] +=  separ + "S=" + multi.at(ii).category.toLowerCase() ;//DJ_DEBUG
                                                    // nmredata[looop_over_spectra] +=  separ+ "Nwrong="  + multi.at(ii).nH ;//DJ_DEBUG
                                                    conn=-1;tmpi=0;
                                                    while (multi.at(ii).name.find("&",tmpi) > 0){
                                                        tmpi=multi.at(ii).name.find("&",tmpi);
                                                        tmpi++;
                                                        conn++;
                                                    }
                                                    if (conn>0){
                                                        nmredata[looop_over_spectra] += separ + "N=" +  conn;//UZ
                                                    }
                                                    // nmredata[looop_over_spectra] +=  separ + "L="  + multi.at(ii).name.replace(/,/g,"&");//DJ_DEBUG
                                                    nmredata[looop_over_spectra] +=  separ + "L="  + "H" + atomLabel;//DJ_DEBUG
                                                    nmredata[looop_over_spectra] +=  separ + "E="  + multi.at(ii).integralValue(1e3).toFixed(4);//DJ_DEBUG
                                                    lll=multi.at(ii).jList();
                                                    for (j = 0; j < lll.length; ++j) {
                                                        if (j === 0){
                                                            nmredata[looop_over_spectra] +=  separ + "J=" ;//DJ_DEBUG
                                                        }
                                                        nmredata[looop_over_spectra] +=  lll.at(j).toFixed(2);//DJ_DEBUG
                                                        if (j+1 !== lll.length){
                                                            nmredata[looop_over_spectra] +=  "," ;//DJ_DEBUG
                                                        }
                                                    }
                                                    nmredata[looop_over_spectra] +=  "; found H multiplet by label chem shifts differ by " + Number(chem_shift- multi.at(ii).delta).toFixed(6) + " ppm\n";//DJ_DEBUG
                                                }
                                            }
                                        }
                                        ii++;
                                    }
                                    if (found_sih === 0){// still not found... write comment...
                                        
                                        
                                        nmredata[looop_over_spectra] += ";" + shiftH + ", L="  + "H" + atomLabel + ";found no H multiplet for this H\n";//.toFixed(4);//DJ_DEBUG
                                        
                                    }
                                    
                                    
                                    
                                    
                                }else{
                                    nmredata[looop_over_spectra] +=  mul + "; found multiplet for this H Will remove...\n";//.toFixed(4);//DJ_DEBUG
                                    found_sih=1;
                                }
                                
                            }    // is now here
                            
                        }
                    }
                    
                }
                
                ii=0;
                while (ii < multi.count) {
                    
                    
                    label="emptylabel";
                    
                    //  nmredata[looop_over_spectra] +=  " 1=M== = " + ii + " " + multi + " \n";
                    //  nmredata[looop_over_spectra] +=  " ===== = " + ii + " " + multi.at(ii) + " \n";
                    if (debug) {
                        nmredata[looop_over_spectra] += ";; for debug multiplet " + ii + "id:< " + multi.at(ii).id + "> " +  multi.at(ii).delta.toFixed(4) ;//DJ_DEBUG
                        nmredata[looop_over_spectra] +=  separ + "S=" + multi.at(ii).category.toLowerCase() ;//DJ_DEBUG
                        nmredata[looop_over_spectra] +=  separ + "Nwrong="  + multi.nH ;//DJ_DEBUG
                        nmredata[looop_over_spectra] +=  " multiId <" +  aAssignmentObject.multipletAssignment(multi.at(ii).id) + ">";
                        nmredata[looop_over_spectra] +=  " peakId <" +  aAssignmentObject.peakAssignment(multi.at(ii).id) + ">";
                        nmredata[looop_over_spectra] +=  " category <" +  multi.at(ii).category + ">";
                        nmredata[looop_over_spectra] +=  " name <" +  multi.at(ii).name + ">";
                        nmredata[looop_over_spectra] +=  " name <" +  multi.at(ii).integralValue(1e3) + ">";
                        //       nmredata[looop_over_spectra] +=  ";DEBUG MULTI multiId <" +  aAssignmentObject.multipletAssignment(ii,"C") + ">";
                        //       nmredata[looop_over_spectra] +=  ";DEBUG MULTI peakId <" +  aAssignmentObject.peakAssignment(ii) + ">";
                        /*  atomNH = aAssignmentReporter.nucleids[multi.at(ii).name + "_" + shift];
                         nmredata[looop_over_spectra] +=  ", Nd="  + atomNH ;//DJ_DEBUG
                         
                         atomNH = aAssignmentReporter.nucleids[multi.at(ii).name + "_1" ];
                         nmredata[looop_over_spectra] +=  ", Ne="  + atomNH ;//DJ_DEBUG
                         
                         atomNH = aAssignmentReporter.nucleids[multi.at(ii).name  ];
                         nmredata[looop_over_spectra] +=  ", Nf="  + atomNH ;//DJ_DEBUG
                         
                         nmredata[looop_over_spectra] +=  ", Nn="  + multi.at(ii).name ;//DJ_DEBUG*/
                        
                        
                        nmredata[looop_over_spectra] +=  separ + "L="  + multi.at(ii).name.replace(/,/g,"&");//DJ_DEBUG
                        nmredata[looop_over_spectra] +=  separ + "E="  + multi.at(ii).integralValue(1e3).toFixed(4);//DJ_DEBUG
                        lll=multi.at(ii).jList();
                        for (j = 0; j < lll.length; ++j) {
                            if (j === 0){
                                nmredata[looop_over_spectra] +=  separ + "J=" ;//DJ_DEBUG
                            }
                            //nmredata[looop_over_spectra] +=  ">> " + lll.at(j);
                            nmredata[looop_over_spectra] +=  lll.at(j).toFixed(2);//DJ_DEBUG
                            if (j+1 !== lll.length){
                                nmredata[looop_over_spectra] +=  "," ;//DJ_DEBUG
                            }
                        }
                        
                        nmredata[looop_over_spectra] +=  "; HERE \n";//DJ_DEBUG
                    };
                    ii++;
                }
            }
            //noEqHs = aAssignmentObject.notEqHs(at);
            
            
            if (nmredata_header[looop_over_spectra] !== "" ) {
                
                full_path_orig=spectrum.getParam("Data File Name");
                full_path=spectrum.getParam("Data File Name");
                path_elements = full_path.split("/");seppath="/";
                if (path_elements.length < 3) {
                    path_elements = full_path.split("\\");seppath="\\";
                }
                
                // in case points to fid/ser instead of 2rr
                if (path_elements[path_elements.length-1]==="fid" || path_elements[path_elements.length-1]==="ser"){
                    full_path="";
                    for (lo=0 ; lo <=path_elements.length-2 ; lo ++) {
                        full_path +=  path_elements[lo]  + seppath;
                    }
                    full_path += "pdata/1/2rr" ;
                    
                    //   nmredata[looop_over_spectra] += "--------------" + full_path +  " ----------------------\n";
                    
                    
                    path_elements = full_path.split("/");seppath="/";
                    if (path_elements.length < 3) {
                        path_elements = full_path.split("\\");seppath="\\";
                    }
                    
                }
                
                //   nmredata[looop_over_spectra] += "Exp_name=" + path_elements[path_elements.length-5]  + " ;  not in format\n";
                root_path="";
                for (lo=0 ; lo <=path_elements.length-6 ; lo ++) {
                    root_path +=  path_elements[lo]  + seppath;
                }
                rel_path="";
                for (lo=path_elements.length-5 ; lo <=path_elements.length-2 ; lo ++) {
                    rel_path +=  path_elements[lo]  + seppath;
                }
                nmredata_header[looop_over_spectra] += "Spectrum_Location=file:" + rel_path + "\n";
                nmredata_header[looop_over_spectra] += "zip_file_Location=https://www.dropbox.com/sh/ma8v25g15wylfj4/AAA4xWi5w9yQv5RBLr6oDHila?dl=0\n";
                
                //prepare script to prepare NMR record:
                /*   nmredata[looop_over_spectra] += ";UNIX_CREATE mkdir -p \"" + path_elements[path_elements.length-5]  + "\"\n";
                 nmredata[looop_over_spectra] += ";UNIX_CREATE cp -rp  \"" + root_path + path_elements[path_elements.length-5] + seppath + path_elements[path_elements.length-4] + "\" \"" + path_elements[path_elements.length-5]  + "\"\n";
                 nmredata[looop_over_spectra] += ";UNIX_CREATE rm -r \""    + path_elements[path_elements.length-5] + seppath + path_elements[path_elements.length-4] + seppath + "pdata\"\n";// this is to remove all but the used processing if more than one...
                 nmredata[looop_over_spectra] += ";UNIX_CREATE mkdir -p \"" + path_elements[path_elements.length-5] + seppath + path_elements[path_elements.length-4] + seppath + "pdata\"\n";
                 nmredata[looop_over_spectra] += ";UNIX_CREATE cp -rp  \"" + root_path + path_elements[path_elements.length-5] + seppath + path_elements[path_elements.length-4] + seppath + path_elements[path_elements.length-3] + seppath + path_elements[path_elements.length-2] + "\" \"" + path_elements[path_elements.length-5] + seppath + path_elements[path_elements.length-4] + seppath + path_elements[path_elements.length-3]+ "\"\n";
                 nmredata[looop_over_spectra] += ";UNIX_CREATE cp \"" + path_elements[path_elements.length-5]  + ".mnova\"  \"" + path_elements[path_elements.length-5] + parameters.name_compound + ".mnova" + "\"\n";
                 */
                if ( specIndex+1 === 1){
                    
                    nmredata_header[looop_over_spectra] += ";UNIX_CREATE echo \"" + ";Copy spectra for " + parameters.name_compound + "\"\n";
                    //   nmredata_header[looop_over_spectra] += ";UNIX_CREATE cd \"" + "CSH_NAME_CSH" + seppath + "\"\n";
                }
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE mkdir -p \"" + "CSH_NAME_CSH" + seppath + path_elements[path_elements.length-5] + "\"\n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE if ( -f \"" + full_path_orig + "\" ) then \n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE   cp -rp  \"" + root_path + path_elements[path_elements.length-5] + seppath + path_elements[path_elements.length-4] + "\" \"" + "CSH_NAME_CSH"  + seppath + path_elements[path_elements.length-5]  + "\"\n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE   rm -r \""    + "CSH_NAME_CSH"  + seppath + path_elements[path_elements.length-5] + seppath + path_elements[path_elements.length-4] + seppath + "pdata\"\n";// this is to remove all but the used processing if more than one...
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE   mkdir -p \"" + "CSH_NAME_CSH"  + seppath + path_elements[path_elements.length-5] + seppath + path_elements[path_elements.length-4] + seppath + "pdata\"\n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE   cp -rp  \"" + root_path + path_elements[path_elements.length-5] + seppath + path_elements[path_elements.length-4] + seppath + path_elements[path_elements.length-3] + seppath + path_elements[path_elements.length-2] + "\" \"" + "CSH_NAME_CSH"  + seppath + path_elements[path_elements.length-5] + seppath + path_elements[path_elements.length-4] + seppath + path_elements[path_elements.length-3]+ "\"\n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE else \n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE   if (! $?notok) then\n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE     echo \"Could not find the file :" + full_path_orig + " in " + root_path + "\"\n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE     echo \"Please open a shell and use cd to go into the folder of " + path_elements[path_elements.length-5] + "\"\n";
                //  nmredata_header[looop_over_spectra] += ";UNIX_CREATE     echo \"and copy in the folder CSH_NAME_CSH" + seppath + path_elements[path_elements.length-5] + " located in UNIX_WO_PATH the folder(s): \"\n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE     echo \"type the following command lines:\"\n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE     echo \"cp  \"\\\"\"" + path_elements[path_elements.length-5] + seppath + path_elements[path_elements.length-4] + "\"\\\"" + " " + "\\\"\"" + "UNIX_WO_PATH" + seppath +  "CSH_NAME_CSH" + seppath + path_elements[path_elements.length-5] +  "\"\\" + "\"\n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE     set notok=\"1\" \n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE   else\n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE     echo \"cp  \"\\\"\"" + path_elements[path_elements.length-5] + seppath + path_elements[path_elements.length-4] + "\"\\\"" + " " + "\\\"\"" + "UNIX_WO_PATH" + seppath +  "CSH_NAME_CSH" + seppath + path_elements[path_elements.length-5] +  "\"\\" + "\"\n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE   endif \n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE endif \n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE \n";
            }
            if ( specIndex+1 === spectra){
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE cat  \"" + parameters.name_compound + ".nmredata.sdf\"| grep -v  UNIX_CREATE> \"CSH_NAME_CSH" + "/" + parameters.name_compound + ".nmredata.sdf" + "\"\n";
                // nmredata[looop_over_spectra] += ";UNIX_CREATE cp  \"" + parameters.name_compound + ".sdf\"  \"CSH_NAME_CSH" + "/" + parameters.name_compound + ".sdf" + "\"\n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE if (! $?notok) then\n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE echo \"Zipping folder CSH_NAME_CSH\" \n";
                //     nmredata_header[looop_over_spectra] += ";UNIX_CREATE cd \"" + "CSH_NAME_CSH" + seppath + "\"\n";
                
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE rm \"CSH_NAME_CSH.zip\" \n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE zip -q -r \"CSH_NAME_CSH.zip\" \"CSH_NAME_CSH\" -x \"*.DS_Store\" -x \".*\" -x \"_*\"\n";
                //      nmredata_header[looop_over_spectra] += ";UNIX_CREATE cd ..\n";
                
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE else\n";
                // nmredata_header[looop_over_spectra] += ";UNIX_CREATE echo \"Could not find all spectra. When done with copy, compress the folder in unix with:\" \n";
                // nmredata_header[looop_over_spectra] += ";UNIX_CREATE echo \"cd \"\\\"\"UNIX_WO_PATH" + seppath + "CSH_NAME_CSH" +  "\"\\" + "\"\n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE echo \"cd \"\\\"\"UNIX_WO_PATH"  +  "\"\\" + "\"\n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE echo 'rm  \"CSH_NAME_CSH.zip\" '\n";
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE echo 'zip -q -r \"CSH_NAME_CSH.zip\" \"CSH_NAME_CSH\" -x \"*.DS_Store\" -x \".*\" -x \"_*\"'\n";
                
                nmredata_header[looop_over_spectra] += ";UNIX_CREATE endif\n";
                
            }

            //  getParam("Data File Name")
            // found_it=0;
            
            // 2D spectra
            
            /* for (i = 0; i < aAssignmentReporter.fCorrelations.length; i++) {
             headerRow.push(aAssignmentReporter.fCorrelationsDescription[i]);
             //  emptynmr[i] = true;
             type= aAssignmentReporter.fCorrelationsDescription[i];
             // specIndex=0;
             test_type= "2D-" + type;
             // loop over all spectra
             //   spectra = dw.itemCount("NMR Spectrum");
             // found_it = 1;
             // while ( specIndex < spectra && found_it) {//to list all
             //   while ( specIndex < spectra ) {//to list all
             //      spectrum = new NMRSpectrum(dw.item(specIndex, "NMR Spectrum"));
             if ((spectrum.experimentType === test_type))  {
             item_position[i]=specIndex+1;
             keep_type=type;
             }
             //      specIndex++;
             //  }
             }*/
            
            specIndex++;
        }
        
        for (at = 1; at <= aCount; at++) {
            noEqHs = aAssignmentObject.notEqHs(at);
            atomLabel = aMolecule.atom(at).number;
            element = aMolecule.atom(at).elementSymbol;
            
            for (hIndex = 0; hIndex < noEqHs.length; hIndex++) {
                atomRow = [];
                atomRow.push("");
                h = noEqHs[hIndex];
                shift =  aAssignmentObject.chemShiftArr(at, h);
                
                if (aAssignmentReporter !== undefined) {
                    
                    for (c = 0; c < aAssignmentReporter.fCorrelations.length; c++) {
                        
                        
                        correlations = AssignmentReporter.correlationToString(aAssignmentObject, aMolecule, aProtonDecimals, aCarbonDecimals, at, h, aAssignmentReporter.fCorrelations[c], aFormat);
                        if (aAssignmentReporter.fCorrelationsDescription[i] === undefined && at === 1){
                            if (debug){
                            stream.writeln (";INFO_DEBUG 2D correlation found ... reporter # " + c + "type " + aAssignmentReporter.fCorrelationsDescription[i] + " extracted for atom 1: " + correlations +  "\n");
                            }
                        }
                        if (debug){
                            stream.write(";reporter # " + c + "type " + aAssignmentReporter.fCorrelationsDescription[i] + " extracted : ");
                            stream.writeln(correlations);
                        }
                        if (shift) {//add label in first column
                            if (noEqHs.length > 1) {
                                atomRow[0] = AssignmentReporter.atomIndexToString(atomLabel, at, h, true);
                            } else if (noEqHs.length > 0) {
                                atomRow[0] = AssignmentReporter.atomIndexToString(atomLabel, at, h, false);
                            }
                        }
                        /*
                         label="H" + AssignmentReporter.atomIndexToString(atomLabel, at)
                         if (h==1){
                         label+="a";
                         }else{
                         label+="b";
                         }
                         */
                        if (correlations !== "") {
                            //  emptynmr[c] = false;
                            correlationsArray = correlations.split(", ");
                            correlationsArray.sort(sortFunctionForFloats);
                            
                            correlations = correlationsArray.toString();
                            for (i=0 ; i < correlationsArray.length ; i ++) {
                                nmredata[item_position[c]] += correlationsArray[i];
                                nmredata[item_position[c]] += "/";// separator 2D //////////////////////////////////////////////////
                                if ((element === "H") && (hIndex !== 0)){
                                    nmredata[item_position[c]] += "H"  ;// issue replace...
                                }
                                nmredata[item_position[c]] += "H" + AssignmentReporter.atomIndexToString(atomLabel, at) ;// issue replace...
                                if (noEqHs.length>1){
                                    if (h === 1){
                                        nmredata[item_position[c]] += "a" ;// issue replace...
                                    }else{
                                        nmredata[item_position[c]] += "b" ;// issue replace...
                                    }
                                }
                                nmredata[item_position[c]] += "\n";
                            }
                        }
                        atomRow.push(correlations);
                        
                    }
                    tableRows[atomRow[0]] = atomRow;
                }
            }
        }
        
        
        
        
    }
    if (dataFile !== "") {
        //      for (c = 0; c < aAssignmentReporter.fCorrelations.length; c++) {
        for (c = 1; c <= looop_over_spectra; c++) {

            lab=nmredata_header[c] + nmredata[c];

            if ( lab !== "" ) {
                stream.write(nmredata_header[c]);

                // remove duplicate lines
                tmparr = nmredata[c].split("\n");
                for (ii=0;ii<tmparr.length;ii++){
                    //     stream.writeln(ii);
                    found_one=0;
                    for (iii=0;iii<ii;iii++){
                        // label=tmparr[iii];
                        // lab=tmparr[ii];
                        //stream.writeln(lab);
                        // stream.writeln(tmparr[iii]);
                        //  stream.flush();
                        if (tmparr[iii] !== ""){
                            if (tmparr[ii] !== ""){
                                if (tmparr[ii].find(tmparr[iii],0) > -1) {
                                    found_one=1;
                                }
                            }
                        }
                    }
                    
                    if (found_one === 0){
                        stream.writeln(tmparr[ii]);
                    }
                }
                stream.flush();
                
            }
            //                        stream.writeln(nmredata[c]);

        }
        stream.flush();
        //  file.close;
    }
    return tableRows;
};



AssignmentReporter.removeVoidAssignmentsRows = function (table, lastxNuclidesIndex) {
    "use strict";
    var i, j,
    counter = {},
    newTable = [];
    
    for (i = 1; i < table.length; i++) {
        
        
        for (j = 1; j <= lastxNuclidesIndex; j++) {
            if (table[i][j] !== "") {
                counter[i] = true;
            }
            
        }
    }
    
    newTable.push(table[0]);
    for (i = 0; i < table.length; i++) {
        if (counter[i]) {
            newTable.push(table[i]);
        }
    }
    
    return newTable;
};


AssignmentReporter.removeVoidCorrelationsRows = function (table, startOfCorrelations) {
    "use strict";
    var i, j,
    counter = {},
    newTable = [];
    
    
    for (i = 1; i < table.length; i++) {
        for (j = parseInt(startOfCorrelations + 1, 10); j < table[i].length; j++) {
            if (table[i][j] !== "") {
                counter[i] = true;
            }
        }
    }
    
    newTable.push(table[0]);
    for (i = 0; i < table.length; i++) {
        if (counter[i]) {
            newTable.push(table[i]);
        }
    }
    
    return newTable;
};

AssignmentReporter.removeVoidColumns = function (table) {
    "use strict";
    
    var i, j, row,
    counter = [],
    newTable = [];
    
    for (i = 0; i < table[0].length; i++) {
        counter.push(0);
    }
    
    for (i = 1; i < table.length; i++) {
        for (j = 0; j < table[0].length; j++) {
            if (table[i][j] !== "" && table[i][j] !== undefined && table[i][j] !== "-") {
                counter[j]++;
            }
        }
    }
    
    for (i = 0; i < table.length; i++) {
        row = [];
        for (j = 0; j < counter.length; j++) {
            if (counter[j] !== 0) {
                row.push(table[i][j]);
            }
        }
        newTable.push(row);
    }
    return newTable;
};

AssignmentReporter.getFinalTable =  function (firstTable, secondTable) {
    "use strict";
    
    var i, j, joinedTable = [], aux = [];
    
    if (secondTable) {
        joinedTable.push(firstTable.header.concat(secondTable.header));
        for (i = 0; i < secondTable.header.length; i++) {
            aux.push("");
        }
    } else {
        joinedTable.push(firstTable.header);
    }
    
    for (i in firstTable) {
        if (firstTable.hasOwnProperty(i) && i !== "header") {
            for (j = 0; j < firstTable.header.length; j++) {
                if (firstTable[i][j] === undefined) {
                    firstTable[i][j] = "";
                }
            }
            
            if (secondTable) {
                if (secondTable[i]) {
                    joinedTable.push(firstTable[i].concat(secondTable[i].slice(1)));
                } else {
                    joinedTable.push(firstTable[i].concat(aux));
                }
            } else {
                joinedTable.push(firstTable[i]);
            }
        }
    }
    
    return joinedTable;
};


AssignmentReporter.getOrderedTable =  function (tableRows) {
    'use strict';
    
    var i, k, a, b, temp,
    len = tableRows.length - 1;
    
    for (i = 1; i < len; i++) {
        for (k = 1; k < len; k++) {
            a = parseFloat(tableRows[k][1]);
            b = parseFloat(tableRows[k + 1][1]);
            if (isNaN(a)) {
                a = 0;
            }
            if (isNaN(b)) {
                b = 0;
            }
            if (a < b) {
                temp = tableRows[k + 1];
                tableRows[k + 1] = tableRows[k];
                tableRows[k] = temp;
            }
        }
    }
    return tableRows;
};

AssignmentReporter.getPpmArray =  function (table) {
    'use strict';
    var i,
    ppmArray = [];
    
    for (i = 1; i < table.length; i++) {
        ppmArray[i] = table[i][1];
    }
    return ppmArray;
};

AssignmentReporter.findInformation = function (decimals, multiplets, shifts, atomNH, addNumberOfNuclides, addMultiplicity, labeldj) {
    'use strict';
    
    function greaterThan(a, b) {
        return b - a;
    }
    
    var js, jArray, i, j, k, found, information = "", category, separ = ", ",tmpi,conn;
    
    for (j = 0; j < shifts.length; j++) {
        found = false;
        i = 0;
        information += shifts[j]  ;
        while (i < multiplets.count && !found) {
            
            if (multiplets.at(i).delta.toFixed(decimals) === shifts[j]) {
                found = true;
                //  if (addNumberOfNuclides || addMultiplicity) {
                //information += " (";
                // if (addMultiplicity) {
                
                category = multiplets.at(i).category.toLowerCase();
                information += separ + "S=" + category.toLowerCase() ;
                
                if (addNumberOfNuclides) {
                    if (addMultiplicity) {
                        //information += ", ";
                    }
                    if ((atomNH === 0) || (atomNH === "0")){
                        conn=0;tmpi=0;
                        while (multiplets.at(i).name.find(",",tmpi) > 0){
                            tmpi=multiplets.at(i).name.find(",",tmpi);
                            tmpi++;
                            conn++;
                        }
                        information += separ + "N=" +  (conn+1);//UZ
                    }else{
                        information += separ + "N=" + atomNH ;
                        
                    }
                }
                information += separ + "L=" + multiplets.at(i).name.replace(/,/g,"&");//DJ_DEBUG
                
                if (category !== "m" && category !== "s") {// should be zero...
                    js = multiplets.at(i).jList();
                    information += separ + "J=";
                    //information += ", ";
                    jArray = [];
                    for (k = 0; k < js.length; k++) {
                        jArray[k] = js.at(k).toFixed(2);
                    }
                    
                    jArray.sort(greaterThan); //sort descending
                    
                    for (k = 0; k < jArray.length; k++) {
                        if (k === 0) {
                            information += jArray[k];
                        } else {
                            information += "," + jArray[k];
                        }
                    }
                    
                    //information += " Hz";
                }
                information +=separ +  "E=" + multiplets.at(i).integralValue(1e3).toFixed(4) ;
                //  information += ";" + separ + "Z=" + labeldj ;// this is single label
                
                // }
                
                //information += "), ";
                information += separ;
                // } else {
                //     information += ", ";
                // }
            } else {
                i++;
            }
        }
        
        if (!found) {
            information += separ;
        }
        
    }
    
    if (information !== "") {
        information = information.substring(0, information.length - 2);
    }
    
    return information;
};

AssignmentReporter.atomIndexToString = function (aAtomLabel, aAtomNumber, aHIndex, aUseHIndex) {
    'use strict';
    var str = aAtomLabel;
    
    if (str === "") {
        str = aAtomNumber.toString();
    }
    if (aUseHIndex) {
        str += Str.hIndexToLetter(aHIndex);
    }
    return str;
};

AssignmentReporter.correlationToString = function (assignObject, aMolecule, protonDecimals, carbonDecimals, aAtom, aH, aCorrelation, aFormat) {
    'use strict';
    var i, cShift, cMeanShift, atomLabel,
    corrString = "",
    noEqAtoms,
    useHIndex,
    corrAtoms,
    precisionForShift;
    
    corrAtoms = assignObject.correlatedAtoms(aAtom, aH, aCorrelation);
    
    if (corrAtoms.length) {
        for (i = 0; i < corrAtoms.length; i++) {
            cShift = assignObject.chemShift(corrAtoms[i].atom, corrAtoms[i].indexes[0]);
            if (cShift !== undefined) {
                if (i > 0) {
                    corrString  += ", ";
                }
                atomLabel = aMolecule.atom(corrAtoms[i].atom).number;
                noEqAtoms = assignObject.notEqHs(corrAtoms[i].atom);
                
                if (corrAtoms[i].indexes[0] >= 1) {
                    corrString += "H";
                    
                    corrString += atomLabel;
                    
                    if (corrAtoms[i].indexes[0] === 1 && noEqAtoms.length > 1) {
                        corrString += "a";
                    } else if (corrAtoms[i].indexes[0] === 2 && noEqAtoms.length > 1) {
                        corrString += "b";
                    }
                    
                    precisionForShift = protonDecimals;
                } else if (corrAtoms[i].indexes.length === 1) {
                    
                    //  corrString += aMolecule.atom(corrAtoms[i].atom).elementSymbol + "-here_remove_heavy_atom_label-";
                    if (aMolecule.atom(corrAtoms[i].atom).elementSymbol === "H") {
                        corrString += "H";
                    }
                    useHIndex = (noEqAtoms.length > 1);
                    corrString += AssignmentReporter.atomIndexToString(atomLabel, corrAtoms[i].atom, corrAtoms[i].indexes[0], useHIndex);
                    
                } else {
                    corrString += "H";
                    corrString += atomLabel;
                }
            }
        }
    }
    return corrString;
};

AssignmentReporter.findMultiplicity = function (decimals, multi, shift) {
    'use strict';
    
    function greaterThan(a, b) {
        return b - a;
    }
    
    var js, jArray, j,
    i = 0,
    found = false,
    multiplicity = "";
    
    while (i < multi.count && !found) {
        if (multi.at(i).delta.toFixed(decimals) === shift) {
            found = true;
            multiplicity = multi.at(i).category.toLowerCase();
            if (multiplicity !== "m" && multiplicity !== "s") {
                js = multi.at(i).jList();
                multiplicity += ",<i>J</i>=";
                jArray = [];
                for (j = 0; j < js.length; j++) {
                    jArray[j] = js.at(j).toFixed(decimals);
                }
                
                jArray.sort(greaterThan); //sort descending
                
                for (j = 0; j < jArray.length; j++) {
                    if (j === 0) {
                        multiplicity += jArray[j];
                    } else {
                        multiplicity += "," + jArray[j];
                    }
                }
                multiplicity += " Hz";
            }
        } else {
            i++;
        }
    }
    return multiplicity;
};


AssignmentReporter.assignmentReportCorrelations = function (decimals, aAssignmentObject, aMolecule, aAssignmentReporter, aMulti) {
    'use strict';
    
    //Deprecated
    
    var i, at, noEqHs, hIndex, atomLabel, atomRow, h, shift, hIsHeavyIndex, skip, shiftH, shiftH0, shiftH1, element,
    aCount = aMolecule.atomCount,
    tableRows = {},
    headerRow = [];
    
    if (aAssignmentReporter !== undefined) {
        for (i = 0; i < aAssignmentReporter.fCorrelations.length; i++) {
            headerRow.push(aAssignmentReporter.fCorrelationsDescription[i]);
        }
    }
    tableRows.header = headerRow;
    
    for (at = 1; at <= aCount; at++) {
        noEqHs = aAssignmentObject.notEqHs(at);
        skip = true;
        hIsHeavyIndex = false;
        atomLabel = aMolecule.atom(at).number;
        element = aMolecule.atom(at).elementSymbol;
        
        //  if (noEqHs.length === 0  && element === "C") {
        if (noEqHs.length === 0  ) {
            atomRow = [];
            atomRow[0] = AssignmentReporter.atomIndexToString(atomLabel, at);
            atomRow[1] = "";
            atomRow[2] = AssignmentReporter.findMultiplicity(decimals, aMulti, atomRow[1]);
            shift =  aAssignmentObject.chemShiftArr(at);
            if (shift) {
                if (shift[1]) {
                    shiftH0 = Number((shift[0].max + shift[0].min) / 2).toFixed(decimals);
                    shiftH1 = Number((shift[1].max + shift[1].min) / 2).toFixed(decimals);
                    atomRow[3] = shiftH0 + "," + shiftH1;
                } else {
                    atomRow[3] = Number((shift[0].max + shift[0].min) / 2).toFixed(decimals);
                }
            } else {
                atomRow[3] = "";
            }
            tableRows[atomRow[0]] = atomRow;
        } else {
            
            for (hIndex = 0; hIndex < noEqHs.length; hIndex++) {
                atomRow = [];
                atomRow[0] = AssignmentReporter.atomIndexToString(atomLabel, at);
                atomRow[1] = "";
                atomRow[2] = "";
                h = noEqHs[hIndex];
                if (h === 0) {
                    hIsHeavyIndex = true;//H not attached to any C
                }
                shift =  aAssignmentObject.chemShiftArr(at, h);
                
                if (shift) {
                    if (noEqHs.length > 1) {
                        atomRow[0] = AssignmentReporter.atomIndexToString(atomLabel, at, h, true);
                    } else if (noEqHs.length > 0) {
                        atomRow[0] = AssignmentReporter.atomIndexToString(atomLabel, at, h, false);
                    }
                    skip = false;
                    
                    if (shift[1]) {
                        shiftH0 = Number((shift[0].max + shift[0].min) / 2).toFixed(decimals);
                        shiftH1 = Number((shift[1].max + shift[1].min) / 2).toFixed(decimals);
                        atomRow[1] = shiftH0 + "," + shiftH1;
                        
                    } else {
                        shiftH = Number((shift[0].max + shift[0].min) / 2).toFixed(decimals);
                        if (atomRow[1] !== "") {
                            shiftH = "," + shiftH;
                            atomRow[1] += shiftH;
                        } else {
                            atomRow[1] = shiftH;
                        }
                    }
                }
                atomRow[2] = AssignmentReporter.findMultiplicity(decimals, aMulti, atomRow[1]);
                shift =  aAssignmentObject.chemShiftArr(at);
                //   if (!hIsHeavyIndex && shift && element === "C") {
                if (!hIsHeavyIndex && shift ) {
                    skip = false;
                    
                    if (shift[1]) {
                        shiftH0 = Number((shift[0].max + shift[0].min) / 2).toFixed(decimals);
                        shiftH1 = Number((shift[1].max + shift[1].min) / 2).toFixed(decimals);
                        atomRow[3] = shiftH0 + "," + shiftH1;
                    } else {
                        atomRow[3] = Number((shift[0].max + shift[0].min) / 2).toFixed(decimals);
                    }
                } else {
                    atomRow[3] = "";
                }
                
                tableRows[atomRow[0]] = atomRow;
            }
        }
    }
    return tableRows;
};




if (this.MnUi && MnUi.scripts_nmr) {
    MnUi.scripts_nmr.scripts_nmr_ReportAssignments = assignmentReport;
}
