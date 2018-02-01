Sub ButtonQuery_Click()
    Application.ScreenUpdating = False

    On Error Resume Next

    Dim conn As Object
    Set conn = CreateObject("ADODB.Connection")
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
    conn.ConnectionString = "DS Query"
    conn.Provider = "ADsDSoobject"
    conn.Open
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

        strSql = "<LDAP://china.huawei.com/DC=china,DC=huawei,DC=com>;" & strSql & ";ADsPath;subtree"
        'description,telephoneNumber,physicalDeliveryOfficeName,mail,department,postalCode,streetAddress,sAMAccountName,sn,conn,displayName,homeMDB,pager,memberOf,mobile,proxyAddresses,msExchMobileAllowedDeviceIDs,title,hw-departname1,hw-departname2,hw-departname3,hw-departname4,hw-departname5,info,businesscategory,initials,countrycode,extensionattribute1,extensionattribute2,extensionattribute3,msExchAssistantName,msexchuserculture
        
        rs.Open strSql, conn
        'Worksheets("Query").Range("A2").CopyFromRecordset rs

        If Not rs.EOF Then
            Set user = CreateObject(rs.Fields(0).Value)
            strTemp = user.Title
            strTemp = Mid(strTemp, InStr(strTemp, ",") + 1)
            sheet.[FullName].Cells(i) = Mid(strTemp, 1, InStr(strTemp, ",") - 1) 'Chinese Name
            sheet.[WorkerId].Cells(i) = user.sn  'employ no:
            sheet.[DomainAccount].Cells(i) = user.sAMAccountName 'domin user
            sheet.[NotesId].Cells(i) = user.cn  'name + employ no:
            sheet.[mobile].Cells(i) = user.mobile

            findEmail = False
            findNotes = False
            var = user.proxyAddresses
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
            sheet.[Email].Cells(i) = user.mail
            
            sheet.[Phone].Cells(i) = user.telephoneNumber
            sheet.[Department].Cells(i) = user.physicalDeliveryOfficeName
            ' sheet.Cells(i, 11) = user.department
            sheet.[Location].Cells(i) = user.streetAddress
            sheet.[PostCode].Cells(i) = user.postalCode
            sheet.[Dept1].Cells(i) = user.Get("hw-departname1")
            sheet.[Dept2].Cells(i) = user.Get("hw-departname2")
            sheet.[Dept3].Cells(i) = user.Get("hw-departname3")
            sheet.[Dept4].Cells(i) = user.Get("hw-departname4")
            sheet.[Dept5].Cells(i) = user.Get("hw-departname5")
            sheet.[Business].Cells(i) = user.businesscategory
            sheet.[Gender].Cells(i) = user.initials
            sheet.[countrycode].Cells(i) = user.countrycode
            sheet.[Ext_1].Cells(i) = user.extensionattribute1
            sheet.[Ext_2].Cells(i) = user.extensionattribute2
            sheet.[Ext_3].Cells(i) = user.extensionattribute3
            sheet.[Assistant].Cells(i) = user.msExchAssistantName
            sheet.[Culture].Cells(i) = user.msexchuserculture
            
            sheet.[Result].Cells(i) = "OK"
        Else
            sheet.[Result].Cells(i) = "NOK"
        End If

        rs.Close
NextI:
    Next i
    conn.Close
    'MsgBox "Done"
    'Exit Sub
    Application.ScreenUpdating = True

End Sub
