# Get Windows SID

```
function get-sid
{
    Param ( $DSIdentity )
    $ID = new-object System.Security.Principal.NTAccount($DSIdentity)
    return $ID.Translate( [System.Security.Principal.SecurityIdentifier] ).toString()
}
> $admin = get-sid "Administrator"
> $admin.SubString(0, $admin.Length - 4)
```

or

```
(new-object System.Security.Principal.NTAccount("Administrator")).Translate( [System.Secuncipal.SecurityIdentifier] ).ToString()
```

```
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\UserManager\Users\1044480
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE
```
