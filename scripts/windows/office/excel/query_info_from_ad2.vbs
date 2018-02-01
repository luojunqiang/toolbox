Sub ButtonQuery_Click()
    Application.ScreenUpdating = False

    On Error Resume Next

    Dim cn As Object
    Set cn = CreateObject("ADODB.Connection")
    Dim rs As Object
    Set rs = CreateObject("ADODB.Recordset")
    Dim strCn As String

    Dim searchNo As String
    Dim strSql As String
    Dim sheet As Worksheet
    Dim strEmail As String
    Set sheet = Worksheets("Query")
    Dim i As Integer
    Dim j As Integer
    Dim var As Variant

    'sheet.Range("C2:M" & sheet.UsedRange.Rows.Count).ClearContents
    'sheet.Range("A2:A" & sheet.UsedRange.Rows.Count).ClearContents

    Dim strTemp  As String
    Dim findEmail As Boolean
    Dim findNotes As Boolean

    findEmail = False
    findNotes = False

    'start
    For i = 2 To sheet.UsedRange.Rows.Count
        searchNo = LCase(Trim(sheet.Cells(i, 2)))
        If searchNo = "" Then
            sheet.[Result].Cells(i) = ""
            GoTo NextI
        End If
        sheet.Range(sheet.Cells(i, 3), sheet.Cells(i, 25)).ClearContents

        If InStr(searchNo, "@") > 0 Then 'by email
            strSql = "(&(objectClass=user)(proxyAddresses=smtp:" & searchNo & "))"
        ElseIf Asc(Mid(searchNo, 1, 1)) < 58 Or Mid(searchNo, 1, 2) = "kf" Or Mid(searchNo, 1, 2) = "wx" Then     'by workerId including kf,wx
            If Mid(searchNo, 1, 3) = "000" Then
                searchNo = Mid(searchNo, 4)
            End If
            If Len(searchNo) = 6 Then
                searchNo = "00" & searchNo
            End If
            strSql = "(&(objectClass=user)(sn=" & searchNo & "))"
        Else 'by domain account
            strSql = "(&(objectClass=user)(sAMAccountName=" & searchNo & "))"
        End If

        'strSql = "<LDAP://china.huawei.com/DC=china,DC=huawei,DC=com>;" & strSql & ";msExchWhenMailboxCreated,sAMAccountName,sn,cn,displayName,homeMDB,pager,memberOf,mobile,proxyAddresses,msExchMobileAllowedDeviceIDs;subtree"
        'strSql = "<LDAP://china.huawei.com/DC=china,DC=huawei,DC=com>;" & strSql & ";description,telephoneNumber,physicalDeliveryOfficeName,department,postalCode,streetAddress,msExchWhenMailboxCreated,sAMAccountName,sn,cn,displayName,homeMDB,pager,memberOf,mobile,proxyAddresses,msExchMobileAllowedDeviceIDs,title,hw-departname1,hw-departname2,hw-departname3,hw-departname4,hw-departname5;subtree"
        strSql = "<LDAP://china.huawei.com/DC=china,DC=huawei,DC=com>;" & strSql & ";description,telephoneNumber,physicalDeliveryOfficeName,mail,department,postalCode,streetAddress,sAMAccountName,sn,cn,displayName,homeMDB,pager,memberOf,mobile,proxyAddresses,msExchMobileAllowedDeviceIDs,title,hw-departname1,hw-departname2,hw-departname3,hw-departname4,hw-departname5,info,businesscategory,initials,countrycode,extensionattribute1,extensionattribute2,extensionattribute3,msExchAssistantName,msexchuserculture;subtree"
        'strSql = "<LDAP://china.huawei.com/DC=china,DC=huawei,DC=com>;" & strSql & ";description,telephoneNumber,physicalDeliveryOfficeName,department,postalCode,streetAddress,msExchWhenMailboxCreated,sAMAccountName,sn,cn,displayName,homeMDB,pager,memberOf,mobile,proxyAddresses,msExchMobileAllowedDeviceIDs,title,hw-departname1,hw-departname2,hw-departname3,hw-departname4,hw-departname5,logoncount,info,givename,businesscategory,mailnickname,initials,countrycode,physicaldeliveryofficename,extensionattribute1,extensionattribute2,extensionattribute3,msexchuserculture,mail;subtree"

        cn.ConnectionString = "DS Query"
        cn.Provider = "ADsDSoobject"
        cn.Open
        rs.Open strSql, cn
        'Worksheets("Query").Range("A2").CopyFromRecordset rs

        'logoncount,info,givename,businesscategory,mailnickname,
        'initials,countrycode,physicaldeliveryofficename,
        'extensionattribute1,extensionattribute2,extensionattribute3,msexchuserculture,mail
        'businesscategory,initials,countrycode,extensionattribute1,extensionattribute2,extensionattribute3,msexchuserculture
        If Not rs.EOF Then
            'rs.Fields.Count
            'strTemp = rs.Fields("Description").Value(0)
            'strTemp = Mid(strTemp, InStr(strTemp, ",") + 1)
            'sheet.Cells(i, 3) = Mid(strTemp, 1, InStr(strTemp, ",") - 1) 'Chinese Name

            strTemp = rs.Fields("title").Value
            strTemp = Mid(strTemp, InStr(strTemp, ",") + 1)
            sheet.[FullName].Cells(i) = Mid(strTemp, 1, InStr(strTemp, ",") - 1) 'Chinese Name
            sheet.[WorkerId].Cells(i) = rs.Fields.Item("sn") 'employ no:
            sheet.[DomainAccount].Cells(i) = rs.Fields.Item("sAMAccountName") 'domin user
            sheet.[NotesId].Cells(i) = rs.Fields("cn")  'name + employ no:
            'sheet.Cells(i, 5) = rs.Fields("displayName")  'displayname
            'sheet.Cells(i, 6) = rs.Fields("memberOf").Value(0) 'rs.fields("memberOf").actualsize+1
            sheet.[Mobile].Cells(i) = rs.Fields("mobile")

            findEmail = False
            findNotes = False
            var = rs.Fields("proxyAddresses").Value
            For j = LBound(var) To UBound(var)
                strEmail = Replace(LCase(var(j)), "smtp:", "")
                'Debug.Print strEmail
    
                If Mid(strEmail, Len(strEmail) - 10) = "@huawei.com" Then  'email
                    If Not (findEmail) Then
                        sheet.[Email].Cells(i) = strEmail
                        findEmail = True
                    End If
                ElseIf Mid(strEmail, Len(strEmail) - 20) = "@notesmail.huawei.com" Then  'notes
                    If Not (findNotes) Then
                        sheet.[NotesMail].Cells(i) = strEmail
                        findNotes = True
                    End If
                End If
            Next j
            sheet.[Email].Cells(i) = rs.Fields("mail").Value
            
            sheet.[Phone].Cells(i) = rs.Fields("telephoneNumber").Value
            sheet.[Department].Cells(i) = rs.Fields("physicalDeliveryOfficeName").Value
            ' sheet.Cells(i, 11) = rs.Fields("department").Value
            sheet.[Location].Cells(i) = rs.Fields("streetAddress").Value
            sheet.[PostCode].Cells(i) = rs.Fields("postalCode").Value
            sheet.[Dept1].Cells(i) = rs.Fields("hw-departname1").Value
            sheet.[Dept2].Cells(i) = rs.Fields("hw-departname2").Value
            sheet.[Dept3].Cells(i) = rs.Fields("hw-departname3").Value
            sheet.[Dept4].Cells(i) = rs.Fields("hw-departname4").Value
            sheet.[Dept5].Cells(i) = rs.Fields("hw-departname5").Value
            sheet.[Business].Cells(i) = rs.Fields("businesscategory").Value
            sheet.[Gender].Cells(i) = rs.Fields("initials").Value
            sheet.[CountryCode].Cells(i) = rs.Fields("countrycode").Value
            sheet.[Ext_1].Cells(i) = rs.Fields("extensionattribute1").Value
            sheet.[Ext_2].Cells(i) = rs.Fields("extensionattribute2").Value
            sheet.[Ext_3].Cells(i) = rs.Fields("extensionattribute3").Value
            sheet.[Assistant].Cells(i) = rs.Fields("msExchAssistantName").Value
            sheet.[Culture].Cells(i) = rs.Fields("msexchuserculture").Value
    
            sheet.[Result].Cells(i) = "OK"
        Else
            sheet.[Result].Cells(i) = "NOK"
        End If

        rs.Close
        cn.Close
NextI:
    Next i
    MsgBox "Done"
    'Exit Sub
    Application.ScreenUpdating = True

End Sub
