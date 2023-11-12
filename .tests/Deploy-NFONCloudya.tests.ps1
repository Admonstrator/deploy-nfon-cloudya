Describe "GetDownloadURL Function Tests" {
    BeforeAll {
        . '..\.\Deploy-NFONCloudya.ps1'
    }

    It "gets a valid download URL for the latest version" {
        $result = GetDownloadURL
        $result | Should -Not -BeNullOrEmpty
        $result.URLDefault | Should -Match 'https:\/\/cdn\.cloudya\.com\/cloudya-\d+\.\d+\.\d+-win-msi\.zip'
        $result.URLCRM | Should -Match 'https:\/\/cdn\.cloudya\.com\/cloudya-\d+\.\d+\.\d+-crm-win-msi\.zip'
    }

    It "gets a valid download URL for a specified version" {
        $specifiedVersion = '1.7.0' # replace with a version number you want to test
        $result = GetDownloadURL -Version $specifiedVersion
        $result | Should -Not -BeNullOrEmpty
        $result.URLDefault | Should -Be "https://cdn.cloudya.com/cloudya-$specifiedVersion-win-msi.zip"
        $result.URLCRM | Should -Be "https://cdn.cloudya.com/cloudya-$specifiedVersion-crm-win-msi.zip"
    }
}
