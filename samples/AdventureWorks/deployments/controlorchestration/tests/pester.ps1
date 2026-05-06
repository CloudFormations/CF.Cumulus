Describe "Directory Operations" {
    context "Check Stored Procedures Directory Exists" {
        $scriptRoot = (Resolve-Path -Path ".\..\..\..\").Path
        $directory = Join-Path -Path $scriptRoot -ChildPath "src\samples.metadata\control\Stored Procedures"
        it "Check directory exists" {
            Test-Path -Path $directory |  should be $True
        }
    }
}