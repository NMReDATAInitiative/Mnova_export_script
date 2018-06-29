/*
 -also check in peaklist for 13C assignment... and do not list if not found in peaklist or multiplet
 */
/******************************************************************************************************
Modified by Christophe Fares (from assignmentReport.qs by Damien Jeannerat) June 13th, 2018.
-added the function AssignmentReporter.JReport (which converts the J-couplings from the assignment table
        in MNova to the <NMREDATA_J> tag
-added one line to chose the location and name of export file.
-changed name to NMReDATAExport and added the shortcut key CTRL+3 (with icon) for easy menu launch
 *****************************************************************************************************/
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
    diag, drawnItems, tableText, pageItem, i, standardTable, Jtable, correlationsTable, table, cols, j, width,
    addNumberOfNuclides, addMultiplicity, parameters, correlationsTableStart, assignmentsArray, format,
    lines = 25,
    dw = Application.mainWindow.activeDocument,
    ///////////////
    version_nmredata=1.1,//
    ///////////////
    end_of_line,

    clipBoardKey = "Correlation Reporter/ClipBoard",
    correlations2DKey  = "Correlation Reporter/2D Correlations",
    orderKey = "Correlation Reporter/Order by shift",
    decimalsForProtonKey = "Correlation Reporter/Number of decimals for proton",
    decimalsForCarbonKey = "Correlation Reporter/Number of decimals for carbon and x-nuclei",
    decimalsForJcouplings = "Correlation Reporter/Number of decimals for carbon and x-nuclei",
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




    function exportToFile(aFormat) {
        //	function exportToFile(parameters) {

        function formatHeader(aHeader) {
            var re, header = aHeader.toString();
            re = new RegExp("<(.*?)>|[&;]", 'g');
            header = header.replace(re, '');
            return header;
        }

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
    if (version_nmredata>1.0) {
        end_of_line = "\\\n";
    } else {
            end_of_line = "\n";
    }
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
                            parameters.version_nmredata=version_nmredata;

                            // removed because not good if more than one mnova file for the same dataset
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
                       //     var filename = FileDialog.getSaveFileName("*.nmredata.sdf","Choose file",dataFile,4);
                       //                                 dataFile = filename;


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
                            // output some comments
                            stream.writeln(">  <NMREDATA_VERSION>\n" + version_nmredata + end_of_line );
                            stream.writeln(">  <NMREDATA_LEVEL>\n" + nmredata_level  + end_of_line);
                            stream.writeln(">  <NMREDATA_ID>");
                            stream.writeln("Record=https://www.dropbox.com/sh/ma8v25g15wylfj4/AAA4xWi5w9yQv5RBLr6oDHila?dl=0\\");
                            stream.writeln("Path=compound1.nmredata.sdf\\");
                            stream.writeln("");

                            if (debug){
                                stream.writeln(">  <COMMENT_TO_DEL> ");
                                //stream.writeln(path_elements[path_elements.length-5]);
                                stream.write(";comments on the mol... "  + end_of_line);
                                stream.write(";comments on the mol... " + end_of_line);

                                stream.write(";molName :" + mol.molName + end_of_line);

                                stream.write(";label :" + mol.label + end_of_line);
                                stream.write(";Description :" + mol.Description + end_of_line);
                                stream.write(";molecularFormula :" + mol.molecularFormula() + end_of_line);
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

                                stream.writeln(">  <NMREDATA_SOLVENT>\n" + spectrum.solvent +  end_of_line);

                                found_it=0;

                                specIndex++;

                            }

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


                            drawnItems = [];

                            //	if (diag.exec()) {

                            settings.setValue(correlations2DKey, true);// diag.widgets.gb2DCorrelations.checked);
                            settings.setValue(decimalsForProtonKey, 4);//diag.widgets.sbDecimalsForProton.value);
                            settings.setValue(decimalsForCarbonKey, 4);//diag.widgets.sbDecimalsForCarbon.value);
                            settings.setValue(decimalsForJcouplings, 1);//diag.widgets.sbDecimalsForCarbon.value);
                            settings.setValue(orderKey, true);//diag.widgets.ckOrder.checked);
                            settings.setValue(showShiftKey, true);//diag.widgets.gbShowDeltaForCarbon.checked);
                            settings.setValue(exportToFileKey, true);//diag.widgets.gbExportToFile.checked);
                            settings.setValue(exportingFormatKey, true);//diag.widgets.rbText.checked);
                            settings.setValue(clipBoardKey, true);//diag.widgets.ckClipBoard.checked);
                            settings.setValue(includeMultiplicityKey, true);//diag.widgets.ckIncludeMultiplicity.checked);
                            settings.setValue(addNumberOfNuclidesKey, true);//diag.widgets.ckAddNumberOfNuclides.checked);
                            settings.setValue(dropLinesWithoutCorrelationKey, true);//diag.widgets.ckDropLinesWithoutCorrelation.checked);
                            settings.setValue(showDeltaForCarbonKey, true);//diag.widgets.ckShowDeltaForCarbon.checked);


                            settings.setValue(formatKey, 0);

                            addNumberOfNuclides = true;//diag.widgets.ckAddNumberOfNuclides.checked;
                            addMultiplicity =  true;//diag.widgets.ckIncludeMultiplicity.checked;

                            assignmentsArray = getAssignmentsArray();
                            correlationsTableStart = assignmentsArray.length;

                            standardReporter = new AssignmentReporter(assignmentsArray, "Main", getAssignmentsDescriptions(), "Correlation Reporter/H&C");
                            correlationsReporter = new AssignmentReporter(getCorrelationsArray(), "2D Correlations", getCorrelationsDescriptions(), "Correlation Reporter/2D");

                            parameters.protonDecimals = 4;//diag.widgets.sbDecimalsForProton.value;
                            parameters.carbonDecimals = 4;//diag.widgets.sbDecimalsForCarbon.value;
                            parameters.jcouplingsDecimals = 1;//diag.widgets.sbDecimalsForJcouplings.value;
                            parameters.assignmentObject = assign;
                            parameters.molecule = mol;
                            parameters.reporter = standardReporter;
                            parameters.multi = multi;
                            parameters.addNumberOfNuclides = addNumberOfNuclides;
                            parameters.addMultiplicity = addMultiplicity;
                            parameters.showDeltaForCarbon = true;//diag.widgets.ckShowDeltaForCarbon.checked;
                            // parameters.FileNameNmredata = FileNameNmredata;

                            standardTable = AssignmentReporter.assignmentReport(parameters);
                            JTable = AssignmentReporter.jReport(parameters);

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
    end_of_line,
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
    if (parameters.version_nmredata>1.0) {
        end_of_line = "\\\n";
    } else {
        end_of_line = "\n";
    }

    if (aAssignmentReporter !== undefined) {
        for (i = 0; i < aAssignmentReporter.fCorrelations.length; i++) {
            headerRow.push(aAssignmentReporter.fCorrelationsDescription[i]);
        }
    }


    for (at = 1; at <= aCount; at++) {						// loop over atoms…
        noEqHs = aAssignmentObject.notEqHs(at);
        skip = true;
        hIsHeavyIndex = false;
        atomLabel = aMolecule.atom(at).number;
        element = aMolecule.atom(at).elementSymbol;
        atomNH = aMolecule.atom(at).nHAll;
                  //print(at,atomLabel,noEqHs);
        if (noEqHs.length === 0  && element !== "H") {   // if atom has no attached H and is not an explicit H itself...
            atomRow = [];
            atomRow[0] = AssignmentReporter.atomIndexToString(atomLabel, at);
            shifts = [];
            atomRow[1] = "";
            nmredataLine="";

            if (aCarbonAssignments) {// parameters.showDeltaForCarbon flag
                shift =  aAssignmentObject.chemShiftArr(at);

                if (shift) {
                    if (shift[1]) {
                        shiftH0 = Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon);
                        shiftH1 = Number((shift[1].max + shift[1].min) / 2).toFixed(aDecimalsForCarbon);
                        atomRow[AssignmentReporter.getXNucleus(element, aAssignmentReporter)] = shiftH0 + "," + shiftH1;
                        nmredataLine=   AssignmentReporter.atomIndexToString(atomLabel, at) + separ + Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon) + separ +at;// could add element

                        if (debug_assignment_tag){
                            nmredataLine += "           ;K1";
                        }
                    }
                                        else {
                        atomRow[AssignmentReporter.getXNucleus(element, aAssignmentReporter)] = Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon);
                        nmredataLine=  AssignmentReporter.atomIndexToString(atomLabel, at) + separ + Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon) + separ + at ;// could add element
                        if (debug_assignment_tag){
                            nmredataLine += "             ;K2";
                        }
                    }
                }
                                else {
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
                    stream.write(atomRow + end_of_line);
                }

                if ( nmredataLine !== ""){
                    stream.write(nmredataLine + end_of_line);
                }
                stream.flush();
            }
            //
        }
                else { //if atom has attached 1Hs... or is an explicit H itself

            for (hIndex = 0; hIndex < noEqHs.length; hIndex++) { //...loop over all atoms at that position (0:heavy, 1:first 1H, 2:second 1H...)
                atomRow = [];
                atomRow[0] = AssignmentReporter.atomIndexToString(atomLabel, at);
                atomRow[1] = "";
                shifts = [];
                h = noEqHs[hIndex];
                if (h === 0) {
                    hIsHeavyIndex = true; //flag for explicit 1H
                }
                shift =  aAssignmentObject.chemShiftArr(at, h);

                nmredataLine= "";
                if  (aMolecule.atom(at).elementSymbol !== "H") {
                    implicitH="H";
                }
                                else{
                    implicitH="";
                }

                if (shift) {
                    if (noEqHs.length > 1) { //2 (or more?) 1H attached
                        atomRow[0] = AssignmentReporter.atomIndexToString(atomLabel, at, h, true);
                        label="H" + AssignmentReporter.atomIndexToString(atomLabel, at)

                                                if (h==1){
                            label+="a";
                        }
                                                else{
                            label+="b";
                        }

                        nmredataLine = label + separ + Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon) + separ + implicitH + at ;
                        if (debug_assignment_tag){
                            nmredataLine +=  " ;check explicit H2 is OK ; L3";
                        }
                    }
                                        else{
                                                if (noEqHs.length > 0) {  //if 1 attached implicit 1H
                                                        atomRow[0] = AssignmentReporter.atomIndexToString(atomLabel, at, h, false);
                                                        label="H" + AssignmentReporter.atomIndexToString(atomLabel, at) ;
                                                        nmredataLine = label + separ + Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon) + separ + implicitH + at ;
                                                        if (debug_assignment_tag){
                                                                nmredataLine +=  " ;check explicit H is OK ; L2 element:" + aMolecule.atom(at).elementSymbol + " expli: " + implicitH;
                            }
                                                }
                                        }
                    skip = false;

                    if (shift[1]) {
                        shiftH0 = Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimals);
                        shiftH1 = Number((shift[1].max + shift[1].min) / 2).toFixed(aDecimals);
                        shifts.push(shiftH0);
                        shifts.push(shiftH1);

                    }
                                        else {
                        shiftH = Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimals);
                        shifts.push(shiftH);
                    }

                    if (aAssignmentReporter.nucleids[atomRow[0] + "_" + shift]) {
                        aAssignmentReporter.nucleids[atomRow[0] + "_" + shift]++;
                    }
                                        else {
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
                        stream.write(atomRow + end_of_line);
                    }

                    if ( nmredataLine !== ""){
                        stream.write(nmredataLine + end_of_line);
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
                            nmredataLine =                      + AssignmentReporter.atomIndexToString(atomLabel, at) + separ + shiftH0 + separ +  at ;
                            if (debug_assignment_tag){
                                nmredataLine +=   ";  LC1";
                            }
                            nmredataLine = nmredataLine + "\n" + AssignmentReporter.atomIndexToString(atomLabel, at) + separ + shiftH1 + separ +  at ;
                            if (debug_assignment_tag){
                                nmredataLine += ";  LC2";
                            }
                        } else {
                            atomRow[AssignmentReporter.getXNucleus(element, aAssignmentReporter)] = Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon);
                            value_c_shift=Number((shift[0].max + shift[0].min) / 2).toFixed(aDecimalsForCarbon);
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
                                    stream.write(atomRow + end_of_line);
                                }

                                stream.write(nmredataLine + end_of_line);
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
    stream.writeln("");// end of assignment tag DJ put back Nov 23
                //Step 1: get the active atom A (can be any explicit atom (CHcount=0) in the structure or its implicit attached Hs (CHcount>0))

        /// dj add to dump in file
    if (dataFile !== "") {
        if (debug){
            stream.writeln("");
            // stream.writeln("");
            stream.writeln(">  <DEBUG_1D_1H_NOTOK>");
            stream.write(";not satisfactory..." + end_of_line);
            //	stream.write(lich[ii]); could be used to sort....
            for (ii = 0; ii < counth; ii++) {
                stream.writeln(lith[ii]);
            }
            counth=0;
            stream.writeln("");
            //  stream.writeln("");
            stream.writeln(">  <DEBUG_1D_13C_NOTOK>");
            stream.write(";not satisfactory..." + end_of_line);
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

AssignmentReporter.jReport = function (parameters) {
    'use strict';

    var i, j, at, jc0, jat, jatomNH, jCH, jh, jvalue,
        CHcount,
        atomLabel,
        atomNH,
    end_of_line,
    aAssignmentObject = parameters.assignmentObject,
    aDecimals = parameters.jcouplingsDecimals,
    aMolecule = parameters.molecule,
    mol=parameters.molecule,
    aCount = aMolecule.atomCount;
    stream = parameters.stream,//add dj

    ///  here was ...
    if (parameters.version_nmredata>1.0) {
        end_of_line = "\\\n";
    } else {
        end_of_line = "\n";
    }

        EDATAJstream="";
        for (at = 1; at <= aCount; at++) {   // loop over atoms…
                //print(aMolecule.atom(at));
                atomLabel = aMolecule.atom(at).number; // atomnumber
                atomNH = aMolecule.atom(at).nHAll;		//get number of attached Hs
                if(atomNH==2){	//for CH2: expect up to two H-shifts
                        CHcount=2;						//
                }
                if(atomNH==0){ //for Cquat: expect no H-shift
                        CHcount=0;
                }
                if(atomNH==1 ||atomNH==3 ){ //for CH or CH3: expect up to one  H-shift (might not work for heteroatoms??)
                        CHcount=1;
                }
                for (i = 0; i <= CHcount; i++) { // i is the aIndex i.e.-0 for heavy index. Bigger values to specify a proton number.
                        jc0 = aAssignmentObject.jConsts(at,i);
                        //print(jc0);
                        if (jc0) {
                        print(jc0);
                                if(i==0) {
                                        element = "(" + aMolecule.atom(at).elementSymbol + ")";
                                        atomLabel2 = /**/ "H" + atomLabel;// dj added H for explicit... (could remove it here AND at line 605)
                                }
                                if(i>0 && CHcount == 1) {
                                        element = "(H)";
                                        atomLabel2 = "H" + atomLabel;
                                }
                                if(i>0 && CHcount == 2) {
                                        element ="(H)<" + aMolecule.atom(at).protonLabel(i) +">";
                                        atomLabel2 = "H" + atomLabel + aMolecule.atom(at).protonLabel(i);
                                }
//Step2 : get passive atom B
                                for (j = 0; j < jc0.length; j++) { //cycle through all j-couplings for atom at
                                        jat = jc0[j].atom.index;  //jat is the passive atom number
                                        jatomNH = aMolecule.atom(jat).nHAll;
                                        jh =  jc0[j].atom.h; //jh is the "atom index" of the passive atom (no value:explicit nucleus or a,b,c: one of the implicit attached Hs)
                                        print(jat);
                                        jatomLabel = aMolecule.atom(jat).number;
                                        jCH = 0;
                                        if (jh == "a"){
                                                jCH=1;
                                        }
                                        if (jh == "b"){
                                                jCH=2;
                                        }
                                        if (jh == "c"){
                                                jCH=3;
                                        }
                                        //case 2.1: one of a methylene (CH2) proton: need to add a protonLabel: eg ' or ''
                                        if((jCH == 2 || jCH == 1) && jatomNH == 2) {
                                                jatomLabel2 = "H" + aMolecule.atom(jat).number + aMolecule.atom(jat).protonLabel(jCH);
                                        }
                                        //case 2.2: methyne or methyl (CH or CH3) proton: no need to add a protonLabel: eg ' or ''
                                        if(jCH == 1 && (jatomNH == 1 ||jatomNH == 3)) {
                                                jatomLabel2 = "H" + aMolecule.atom(jat).number;
                                        }
                                        //case 2.3: not an implicit H (this will work for explicit Hs)
                                        if(jCH == 0) {
                                                jatomLabel2 = /**/ "H" + aMolecule.atom(jat).number;// dj added H for explicit... (could remove it here AND at line 605)
                                        }
                                        jvalue =jc0[j].value.toFixed(aDecimals); //this is the J-coupling value
//Step 3: write entry as stream
                                        if (jatomNH < 3 || (jatomNH == 3 && jCH == 1)){
                                                //Case 3.1: coupling between different positions (eg 2J_CC, 3J_HH, 3_JCH)
                                                //setting A<B insures that each coupling is entered only once (e.g. J_AB and not J_BA again later)
                                                if (at < jat) {
                                                        //print(jc0);
                                                        EDATAJstream = EDATAJstream + atomLabel2 + ", " + jatomLabel2 + ", " + jvalue + end_of_line;
                                                }
                                                //Case 3.2: coupling within the same position number (eg 1J_CH, or 2J_HH)
                                                //setting i<jCH ensures no replication of couplings (2JH'H'' but not 2JH''H')
                                                //setting jCH < 3 ensures that methyl group J_CH don't get entered 3 times)
                                                if (at == jat && i < jCH && jCH < 3 ) {
                                                        EDATAJstream = EDATAJstream + atomLabel2 + ", " + jatomLabel2 + ", " + jvalue + end_of_line;
                                                }
                                        }
                                }
                        }
                }
        }
        stream.writeln(">  <NMREDATA_J>");
        stream.writeln(EDATAJstream);// end of jcoup tag

        return EDATAJstream;

};

AssignmentReporter.assignmentReportWithCorrelations = function (parameters) {
    'use strict';

    var i, at, noEqHs, hIndex, atomRow, h, c, shift, atomLabel, element, correlations,
    end_of_line ,
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
    if (parameters.version_nmredata>1.0) {
        end_of_line = "\\\n";
    } else {
        end_of_line = "\n";
    }
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

                nmredata_header[looop_over_spectra] += "Larmor=" + spectrum.frequency(spectrum.dimCount)  + end_of_line;
                if (spectrum.dimCount === 2) { nmredata_header[looop_over_spectra] += "CorrType=" + keep_type  + end_of_line; }
                //   nmredata[looop_over_spectra] += "MnovaType=" + spectrum.experimentType + " ;optional\n";
                //   nmredata[looop_over_spectra] += "MnovaSpecCount=" + spectrum.specCount + " ;optional\n";
                //   nmredata[looop_over_spectra] += "OriginalFormat=" + spectrum.originalFormat + " ;optional in V1\n";
                nmredata_header[looop_over_spectra] += "Pulseprogram=" + spectrum.getParam("Pulse Sequence") + " ;optional in V1" + end_of_line;
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
                                nmredata[looop_over_spectra] +=  mul + "; found multiplet by chemical shift " + end_of_line;
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
                                            nmredata[looop_over_spectra] +=  "; found multiplet by label chem shifts differ by " + Number(mul- multi.at(ii).delta).toFixed(6) + " ppm"  + end_of_line;//DJ_DEBUG

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

                                        nmredata[looop_over_spectra] +=   end_of_line ;
                                        if (debug){
                                            nmredata[looop_over_spectra] +=  " 13Cmul <" + tmpll.c13Multiplicity  + ">";
                                            nmredata[looop_over_spectra] +=  " flagtostring() <" + tmpll.flagsToString()  + ">";//peak.compoundLabel(spec.solvent)
                                            nmredata[looop_over_spectra] +=  " compoundLabel() <" + tmpll.compoundLabel(spectrum.solvent)  + ">";
                                            nmredata[looop_over_spectra] +=  " kindToString() <" + tmpll.kindToString()  + ">";
                                            nmredata[looop_over_spectra] +=  " kurtosis <" + tmpll.kurtosis  + ">";
                                            nmredata[looop_over_spectra] +=  " distance... <" + smallest_cs  + ">";
                                            nmredata[looop_over_spectra] += separ + "w=" + tmpll.width(0)  ;
                                            nmredata[looop_over_spectra] += separ + "v*larmor=" + tmpll.width(0)*spectrum.frequency(spectrum.dimCount)  ;
                                            nmredata[looop_over_spectra] +=   end_of_line ;
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
                                        nmredata[looop_over_spectra] += " (smallest:" + smallest_cs.toFixed(6) + ")"  + end_of_line;
                                    }else{
                                        nmredata[looop_over_spectra] +=  end_of_line ;

                                    }


                                }
                                /// end search....



                            }
                            if (debug){
                                nmredata[looop_over_spectra] +=  "; --- " + mul + ">>;MX El.:" + element + " lab:<" + atomLabel + "> CS 0:" + shift[0].max.toFixed(4) + "-" + shift[0].min.toFixed(4) ;//.toFixed(4);//DJ_DEBUG
                                if (shift[1]) {//  this should be useless because this is the heavy atom...
                                    nmredata[looop_over_spectra] +=   "CS 1:" + shift[1].max.toFixed(4) + "-" + shift[1].min.toFixed(4) ;//.toFixed(4); .DJ_DEBUG

                                }
                                nmredata[looop_over_spectra] +=   end_of_line;

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
                                if (debug)      nmredata[looop_over_spectra] +=  end_of_line;//.toFixed(4);//DJ_DEBUG

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
                                                    nmredata[looop_over_spectra] +=  "; found H multiplet by label chem shifts differ by " + Number(chem_shift- multi.at(ii).delta).toFixed(6) + " ppm" + end_of_line;//DJ_DEBUG
                                                }
                                            }
                                        }
                                        ii++;
                                    }
                                    if (found_sih === 0){// still not found... write comment...


                                        nmredata[looop_over_spectra] += ";" + shiftH + ", L="  + "H" + atomLabel + ";found no H multiplet for this H" + end_of_line;//.toFixed(4);//DJ_DEBUG

                                    }




                                }else{
                                    nmredata[looop_over_spectra] +=  mul + "; found multiplet for this H Will remove..." + end_of_line;//.toFixed(4);//DJ_DEBUG
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

                        nmredata[looop_over_spectra] +=  "; HERE " + end_of_line;//DJ_DEBUG
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
                nmredata_header[looop_over_spectra] += "Spectrum_Location=file:" + rel_path + end_of_line;
              /*  nmredata_header[looop_over_spectra] += "zip_file_Location=https://www.dropbox.com/sh/ma8v25g15wylfj4/AAA4xWi5w9yQv5RBLr6oDHila?dl=0"  + end_of_line;*/

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
                            stream.writeln (";INFO_DEBUG 2D correlation found ... reporter # " + c + "type " + aAssignmentReporter.fCorrelationsDescription[i] + " extracted for atom 1: " + correlations  + end_of_line);
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
                                nmredata[item_position[c]] +=  end_of_line;
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



if (this.MnUi && MnUi.scripts_nmr) {
    MnUi.scripts_nmr.scripts_nmr_ReportAssignments = assignmentReport;
}
