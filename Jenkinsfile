Checkout
stage('Checkout') {
  steps {
	      // Удаление всех файлов из рабочего каталога на сервере TestNode
		bat 'del /F /S /Q *.*'
		// Удаление всех папок из рабочего каталога на сервере TestNode
		bat 'for /d %%x in (.\\*) do @rd /s /q %%x'
		// Вывод echo в консоль Jenkins
		echo 'step Git Checkout'
		// Извлечение из системы контроля версий в рабочий каталог на сервере TestNode
		checkout scm
	}
}

Build
stage('Build') {
	// Команда when позволяет конвейеру определять, следует ли выполнять этап в зависимости от заданного условия.
	when {
		// Заданное условие expression. Оно задается пользователем при запуске конвейера и передается в скрипт через параметр "BUILD"
		expression {
			return params.BUILD
		}
	}
	// Начало шага сборки SSIS-проекта
	steps {
		// Вызов функции PrintStage(). Её мы рассмотрим далее.
		PrintStage()
		echo "step Build Solution"
		/* Вызов SSISBuild.exe на TestNode. Кстати, здесь применяется три подстановки:
		 - переменная среды ${WORKSPACE} - абсолютный путь рабочей области.
		 - глобальные переменные ${SSISBuildPath} и ${SOLUTION} - они задавались в разделе environment */
		bat "${SSISBuildPath} -p:${WORKSPACE}\\${SOLUTION}"
	}
}

Deploy
stage("Deploy to Dev Env") {
	when {
		expression {
			return params.DEPLOY
		}
	}
	steps {
		PrintStage()
		// Использование стандартного плагина Jenkins для архивации собранного SSIS-проекта
		zip zipFile: 'archive.zip', archive: false
		// Самое интересное. Для деплоя полученного файла будем применять службу удаленного управления Windows WinRM в PowerShell
		// Используем учетную запись 'WINRM_PASS' для извлечения SecretText из Jenkins. Учетная запись заведена в Jenkins. Как её добавить я покажу ниже
		withCredentials([string(credentialsId: 'WINRM_PASS', variable: 'WINRM_PASS')]) {
			// Применение скриптового синтаксиса внутри декларативного.
			script {
				// Определяем переменные
				def err
				def stdout = powershell label: 'deploy', returnStdout: true, script: '''
						# Задаем пароль учетной записи WinRM в SecureString
						$pw = convertto-securestring -AsPlainText -Force -String $env:WINRM_PASS
						# Задаем учетные данные для создания сессии WinRM
						$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist "Domain\\User",$pw
						# Открываем сессию
						$s = New-PSSession -ComputerName <server> -Credential $cred
						#Создаем папку на удаленном сервере для копирования архива
						$remotePath = \'D:\\DIGAUD\\TestSSISPipeline\'
						$job = Invoke-Command -Session $s `
												-ScriptBlock {
													if (!(Test-Path -Path \'D:\\DIGAUD\\TestSSISPipeline\')) {mkdir $Using:remotePath}
													} `
												-AsJob
						Wait-Job $job
						$r = Receive-Job $job

						# Копируем архив
						$path = Get-Location
						$dest = Join-Path $path "archive.zip"
						Copy-Item -Path $dest `
									-Destination $remotePath `
									-ToSession $s

						# Распаковываем архив
						$job = Invoke-Command -Session $s `
											  -ScriptBlock {
												   Expand-Archive -LiteralPath \'D:\\Jenkins\\TestSSISPipeline\\archive.zip' -DestinationPath \'D:\\Jenkins\\TestSSISPipeline\'
												  } `
											  -AsJob
						Wait-Job $job
						$r = Receive-Job $job

						#Деплоим
						$job = Invoke-Command -Session $s `
											  -ScriptBlock {
													C:\\SSIS_DEV_OPS\\ssisdeploy.exe -s:\"D:\\Jenkins\\TestSSISPipeline\\AUDIT_Import_ALL\\bin\\Development\\AUDIT_Import_ALL.ispac\" -d:\"catalog;/SSISDB/AUDIT_Import_ALL;mssql_server,port\" -at:win
												   } `
											  -AsJob
						Wait-Job $job
						$r = Receive-Job $job

						Remove-PSsession $s
					   '''
				}
			}
		}
	}
}