
$n = 'MNGENV_DOCINTEL_ENDPOINT_URI'
$v = 'https://di-ac-ae-001.cognitiveservices.azure.com/'
[Environment]::SetEnvironmentVariable($n, $v, "User")

$n = 'MNGENV_DOCINTEL_API_KEY'
$v = '***'
[Environment]::SetEnvironmentVariable($n, $v, "User")

$n = 'MNGENV_TRANSLATOR_ENDPOINT_URI'
$v = 'https://trls-ac-ae-001.cognitiveservices.azure.com/'
[Environment]::SetEnvironmentVariable($n, $v, "User")

$n = 'MNGENV_TRANSLATOR_API_KEY'
$v = '***'
[Environment]::SetEnvironmentVariable($n, $v, "User")

