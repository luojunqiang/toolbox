function showAttr(obj, attr) {
    WScript.Echo("  " + attr + ": " + obj.Get(attr));
}
function showAttrEx(obj, attr) {
    WScript.Echo("  " + attr + ": " + obj.GetEx(attr));
}

function Search(search, SearchType) {
    var arrSearchResult = [];
    var strSearch = '';
    switch (SearchType) {
        case "contains":
            strSearch = "*" + search + "*";
            break;
        case "begins":
            strSearch = search + "*";
            break;
        case "ends":
            strSearch = "*" + search;
            break;
        case "exact":
            strSearch = search;
            break;
        default:
            strSearch = "*" + search + "*";
            break;
    }

    objRootDSE = GetObject("LDAP://RootDSE");
    objRootDSE = GetObject("LDAP://china.huawei.com/RootDSE");
    strDomain = objRootDSE.Get("DefaultNamingContext");

    strOU = "OU=Users"; // Set the OU to search here.    
    strOU = "CN=Users"; // Set the OU to search here.
    strOU = "OU=CorpUsers"; // Set the OU to search here.

    strAttrib = "name,samaccountname"; // Set the attributes to retrieve here.
    strAttrib = "sAMAccountName, givenName, SN, mail";
    strAttrib = "*";
    

    objConnection = new ActiveXObject("ADODB.Connection");
    objConnection.Provider = "ADsDSOObject";
    objConnection.Open("ADs Provider");
    objCommand = new ActiveXObject("ADODB.Command");
    objCommand.ActiveConnection = objConnection;
    var Dom = "LDAP://" + strOU + "," + strDomain;
    WScript.Echo("ldap: " + Dom);
    ///Dom = Dom + "xx";
    var arrAttrib = strAttrib.split(",");
    objCommand.CommandText = "select '" + strAttrib + "' from '" + Dom + "' WHERE objectCategory = 'user' AND objectClass='user' AND sAMAccountName='" + search + "' ORDER BY samaccountname ASC";
    objCommand.CommandText = "select * from '" + Dom + "' WHERE objectCategory = 'user' AND objectClass='user' AND sAMAccountName='" + search + "' ORDER BY samaccountname ASC";
    // objCommand.CommandText = "select mail from '" + Dom + "' WHERE objectCategory = 'user' AND objectClass='user' AND sAMAccountName='" + search + "' ORDER BY samaccountname ASC";
    // objCommand.CommandText = "select mail from '" + Dom + "' WHERE objectCategory = 'user' ORDER BY sAMAccountName ASC";
    WScript.Echo(objCommand.CommandText);

    // try {

        objRecordSet = objCommand.Execute();

        objRecordSet.Movefirst;
        while (!(objRecordSet.EoF)) {
            var locarray = new Array();
            // for (var y = 0; y < arrAttrib.length; y++) { 
            WScript.Echo("field count: " + objRecordSet.Fields.Count);
            for (var y = 0; y < objRecordSet.Fields.Count; y++) { 
                locarray.push(objRecordSet.Fields(y).value); 
                WScript.Echo(objRecordSet.Fields(y).name + ": " + objRecordSet.Fields(y).value);
                var user = GetObject(objRecordSet.Fields(y).value);
                showAttr(user, "Department");
                showAttr(user, "Description");
                showAttr(user, "cn");
                showAttr(user, "mail");
                //showAttr(user, "employeeID");
                // showAttr(user, "facsimileTelephoneNumber");
                showAttr(user, "givenName");
                showAttr(user, "displayName");
                showAttr(user, "sn");
                // showAttr(user, "manager");
                // showAttr(user, "personalTitle");
                // showAttr(user, "generationQualifier");
                // showAttr(user, "middleName");
                // showAttr(user, "postalAddress");
                // showAttr(user, "SeeAlso");
                // showAttr(user, "homePhone");
                showAttr(user, "mobile");
                showAttr(user, "telephoneNumber");
                showAttrEx(user, "otherTelephone");
                showAttr(user, "otherHomePhone");

                showAttr(user, "hw-DepartName1");
                showAttr(user, "hw-DepartName2");
                showAttr(user, "hw-DepartName3");
                showAttr(user, "hw-DepartName4");
                showAttr(user, "hw-DepartName5");
                showAttr(user, "hw-DepartName6");
                // hw-DepartName2
                
                
                
                // showAttr(user, "pager");
                showAttr(user, "title");
                showAttr(user, "streetAddress");
                                
                showAttr(user, "physicalDeliveryOfficeName");
                WScript.Echo("xx:" + user.employeeId);
            } 
            arrSearchResult.push(locarray); 
            objRecordSet.MoveNext;
        } 
        return arrSearchResult;
//     } catch (e) {
//         WScript.Echo("Search failed.")
//         WScript.Echo(e.message);
//     }
}

var r = Search("l00231957", "exact");
