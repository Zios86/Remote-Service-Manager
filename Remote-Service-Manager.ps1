#requires -Version 5.1

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Remote Service Manager — Windows и Linux" Height="780" Width="1450"
        MinHeight="560" MinWidth="900" WindowStartupLocation="CenterScreen"
        Background="#F3F6FA" FontFamily="Segoe UI">
    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="120"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0" Background="White" CornerRadius="10" Padding="14" Margin="0,0,0,10">
            <WrapPanel>
                <TextBlock Text="Система:" VerticalAlignment="Center" Margin="0,0,8,6" FontWeight="SemiBold"/>
                <ComboBox Name="TargetTypeBox" Width="105" Height="32" SelectedIndex="0" Margin="0,0,12,6">
                    <ComboBoxItem Content="Windows"/>
                    <ComboBoxItem Content="Linux"/>
                </ComboBox>
                <TextBlock Text="Компьютер/IP:" VerticalAlignment="Center" Margin="0,0,8,6" FontWeight="SemiBold"/>
                <TextBox Name="ComputerBox" Width="220" Height="32" Padding="8,5" Margin="0,0,12,6" VerticalContentAlignment="Center"/>
                <CheckBox Name="CredentialCheck" Content="Другие учётные данные" VerticalAlignment="Center" Margin="0,0,14,6"/>
                <WrapPanel Name="LinuxOptionsPanel" Visibility="Collapsed">
                    <CheckBox Name="UseCurrentAccountCheck" Content="Текущая УЗ" IsChecked="True" VerticalAlignment="Center" Margin="0,0,10,6"
                              ToolTip="Использовать имя текущей доменной учётной записи Windows и её SSH-ключ/ssh-agent"/>
                    <TextBlock Text="SSH-пользователь:" VerticalAlignment="Center" Margin="0,0,6,6"/>
                    <TextBox Name="LinuxUserBox" Width="220" Height="32" Padding="8,5" Margin="0,0,8,6" IsEnabled="False"
                             ToolTip="Доменное имя обычно имеет вид user@domain"/>
                    <TextBlock Text="Порт:" VerticalAlignment="Center" Margin="0,0,6,6"/>
                    <TextBox Name="LinuxPortBox" Text="22" Width="55" Height="32" Padding="8,5" Margin="0,0,8,6"/>
                    <TextBox Name="LinuxKeyBox" Width="230" Height="32" Padding="8,5" Margin="0,0,6,6" ToolTip="Путь к закрытому SSH-ключу; можно оставить пустым для ssh-agent"/>
                    <Button Name="BrowseLinuxKeyButton" Content="SSH-ключ…" Height="32" Padding="12,0" Margin="0,0,10,6"/>
                </WrapPanel>
                <Button Name="ConnectButton" Content="Подключиться" Height="34" Padding="18,0" Margin="0,0,14,6" Background="#1769E0" Foreground="White" BorderThickness="0" FontWeight="SemiBold"/>
                <TextBlock Name="ConnectionStatus" Text="Не подключено" VerticalAlignment="Center" Margin="0,0,0,6" Foreground="#667085"/>
            </WrapPanel>
        </Border>

        <Border Grid.Row="1" Name="ServicesToolbar" Background="White" CornerRadius="10" Padding="12" Margin="0,0,0,10">
            <WrapPanel>
                <TextBox Name="SearchBox" Width="280" Height="32" Padding="8,5" Margin="0,0,8,6" ToolTip="Поиск по имени или описанию службы"/>
                <ComboBox Name="StateFilter" Width="150" Height="32" Margin="0,0,8,6" SelectedIndex="0">
                    <ComboBoxItem Content="Все состояния"/>
                    <ComboBoxItem Content="Запущенные"/>
                    <ComboBoxItem Content="Остановленные"/>
                    <ComboBoxItem Content="Ошибочные"/>
                </ComboBox>
                <ComboBox Name="GroupFilter" Width="190" Height="32" Margin="0,0,8,6" SelectedIndex="0">
                    <ComboBoxItem Content="Все группы"/>
                </ComboBox>
                <Button Name="SelectAllButton" Content="Выбрать показанные" Height="32" Padding="12,0" Margin="0,0,6,6"/>
                <Button Name="ClearButton" Content="Снять выбор" Height="32" Padding="12,0" Margin="0,0,6,6"/>
                <Button Name="RefreshButton" Content="Обновить" Height="32" Padding="12,0" Margin="0,0,6,6"/>
                <Button Name="CollapseGroupsButton" Content="Свернуть группы" Height="32" Padding="11,0" Margin="0,0,6,6"/>
                <Button Name="ExpandGroupsButton" Content="Развернуть группы" Height="32" Padding="11,0" Margin="0,0,6,6"/>
                <Button Name="ExportButton" Content="Экспорт CSV" Height="32" Padding="12,0" Margin="0,0,6,6"/>
                <Button Name="MonitorProcessesButton" Content="Мониторинг процессов" Height="32" Padding="14,0" Margin="0,0,8,6"
                        Background="#1769E0" Foreground="White" BorderThickness="0"/>
                <TextBlock Name="CountText" Text="Служб: 0" VerticalAlignment="Center" Margin="0,0,0,6" FontWeight="SemiBold"/>
            </WrapPanel>
        </Border>

        <Border Grid.Row="2" Background="White" CornerRadius="10" Padding="6" Margin="0,0,0,10">
            <TabControl Name="MainTabs" BorderThickness="0" Background="White">
                <TabItem Header="Службы">
                    <DataGrid Name="ServicesGrid" AutoGenerateColumns="False" IsReadOnly="False"
                              CanUserAddRows="False" CanUserDeleteRows="False" SelectionMode="Extended"
                              CanUserResizeColumns="False" MinColumnWidth="42"
                              HorizontalScrollBarVisibility="Auto" VerticalScrollBarVisibility="Auto"
                              GridLinesVisibility="Horizontal" HeadersVisibility="Column" AlternatingRowBackground="#F8FAFC">
                        <DataGrid.GroupStyle>
                            <GroupStyle>
                                <GroupStyle.ContainerStyle>
                                    <Style TargetType="{x:Type GroupItem}">
                                        <Setter Property="Template">
                                            <Setter.Value>
                                                <ControlTemplate TargetType="{x:Type GroupItem}">
                                                    <Expander IsExpanded="False" Margin="0,3,0,2">
                                                        <Expander.Header>
                                                            <Border Background="#EAF2FF" Padding="10,7">
                                                                <StackPanel Orientation="Horizontal">
                                                                    <CheckBox Tag="GroupSelector" Margin="0,0,9,0" VerticalAlignment="Center" IsThreeState="True"
                                                                              Focusable="False" ToolTip="Выбрать или снять выбор со всех служб этой категории"/>
                                                                    <TextBlock Text="{Binding Name}" FontWeight="SemiBold" Foreground="#175CD3"/>
                                                                    <TextBlock Text="{Binding ItemCount, StringFormat=  — {0} служб}" Foreground="#667085"/>
                                                                </StackPanel>
                                                            </Border>
                                                        </Expander.Header>
                                                        <ItemsPresenter/>
                                                    </Expander>
                                                </ControlTemplate>
                                            </Setter.Value>
                                        </Setter>
                                    </Style>
                                </GroupStyle.ContainerStyle>
                            </GroupStyle>
                        </DataGrid.GroupStyle>
                        <DataGrid.Columns>
                            <DataGridCheckBoxColumn Header="✓" Binding="{Binding IsChecked, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" Width="42"/>
                            <DataGridTextColumn Header="Имя службы" Binding="{Binding Name}" Width="240" MinWidth="220" IsReadOnly="True"/>
                            <DataGridTextColumn Header="Отображаемое имя" Binding="{Binding DisplayName}" Width="*" MinWidth="320" IsReadOnly="True"/>
                            <DataGridTextColumn Header="Состояние" Binding="{Binding State}" Width="110" MinWidth="100" IsReadOnly="True"/>
                            <DataGridTextColumn Header="Тип запуска" Binding="{Binding StartMode}" Width="120" MinWidth="110" IsReadOnly="True"/>
                        </DataGrid.Columns>
                    </DataGrid>
                </TabItem>
                <TabItem Header="Процессы">
                    <Grid Margin="4">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>
                        <Grid Grid.Row="0" Margin="0,0,0,6">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="250"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="90"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBox Grid.Column="0" Name="ProcessSearchBox" Height="30" Padding="8,4" ToolTip="Поиск по имени или PID"/>
                            <TextBlock Grid.Column="1" Text="Интервал:" VerticalAlignment="Center" Margin="12,0,6,0"/>
                            <ComboBox Grid.Column="2" Name="ProcessIntervalBox" Height="30" SelectedIndex="1">
                                <ComboBoxItem Content="2 сек" Tag="2"/>
                                <ComboBoxItem Content="5 сек" Tag="5"/>
                                <ComboBoxItem Content="10 сек" Tag="10"/>
                                <ComboBoxItem Content="30 сек" Tag="30"/>
                            </ComboBox>
                            <Button Grid.Column="3" Name="ProcessMonitorButton" Content="▶ Мониторинг" Height="30" Padding="12,0" Margin="8,0,6,0" Background="#1769E0" Foreground="White" BorderThickness="0"/>
                            <Button Grid.Column="4" Name="ProcessRefreshButton" Content="Обновить" Height="30" Padding="12,0" Margin="0,0,6,0"/>
                            <Button Grid.Column="5" Name="KillProcessButton" Content="Завершить процесс" Height="30" Padding="12,0" Background="#C62828" Foreground="White" BorderThickness="0"/>
                            <TextBlock Grid.Column="7" Name="ProcessCountText" Text="Процессов: 0" VerticalAlignment="Center" FontWeight="SemiBold"/>
                        </Grid>
                        <DataGrid Grid.Row="1" Name="ProcessesGrid" AutoGenerateColumns="False" IsReadOnly="False"
                                  CanUserAddRows="False" CanUserDeleteRows="False" SelectionMode="Extended"
                                  GridLinesVisibility="Horizontal" HeadersVisibility="Column" AlternatingRowBackground="#F8FAFC"
                                  EnableRowVirtualization="True">
                            <DataGrid.Columns>
                                <DataGridCheckBoxColumn Header="✓" Binding="{Binding IsChecked, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" Width="42"/>
                                <DataGridTextColumn Header="Процесс" Binding="{Binding Name}" Width="*" IsReadOnly="True"/>
                                <DataGridTextColumn Header="PID" Binding="{Binding ProcessId}" Width="75" IsReadOnly="True"/>
                                <DataGridTextColumn Header="CPU, %" Binding="{Binding CpuPercent}" Width="85" IsReadOnly="True"/>
                                <DataGridTextColumn Header="Память, МБ" Binding="{Binding MemoryMB}" Width="105" IsReadOnly="True"/>
                                <DataGridTextColumn Header="Диск, МБ/с" Binding="{Binding DiskMBps}" Width="105" IsReadOnly="True"/>
                                <DataGridTextColumn Header="Потоки" Binding="{Binding ThreadCount}" Width="80" IsReadOnly="True"/>
                                <DataGridTextColumn Header="Дескрипторы" Binding="{Binding HandleCount}" Width="105" IsReadOnly="True"/>
                            </DataGrid.Columns>
                        </DataGrid>
                    </Grid>
                </TabItem>
            </TabControl>
        </Border>

        <Border Grid.Row="3" Name="ServiceActionPanel" Background="White" CornerRadius="10" Padding="12" Margin="0,0,0,10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <WrapPanel Grid.Row="0">
                    <Button Name="StartButton" Content="▶ Запустить" Height="36" Padding="18,0" Margin="0,0,8,6" Background="#16803C" Foreground="White" BorderThickness="0"/>
                    <Button Name="StopButton" Content="■ Остановить" Height="36" Padding="18,0" Margin="0,0,8,6" Background="#C62828" Foreground="White" BorderThickness="0"/>
                    <Button Name="RestartButton" Content="↻ Перезапустить" Height="36" Padding="18,0" Margin="0,0,8,6" Background="#E47C00" Foreground="White" BorderThickness="0"/>
                    <Button Name="RefreshServicesButton" Content="⟳ Обновить список" Height="36" Padding="18,0" Margin="0,0,8,6" Background="#1769E0" Foreground="White" BorderThickness="0" ToolTip="Повторно получить актуальное состояние всех служб"/>
                    <ComboBox Name="StartupTypeBox" Width="150" Height="36" SelectedIndex="0" Margin="0,0,6,6">
                        <ComboBoxItem Content="Automatic"/>
                        <ComboBoxItem Content="Automatic (Delayed)"/>
                        <ComboBoxItem Content="Manual"/>
                        <ComboBoxItem Content="Disabled"/>
                    </ComboBox>
                    <Button Name="SetStartupButton" Content="Изменить тип запуска" Height="36" Padding="14,0" Margin="0,0,8,6"/>
                    <Button Name="DiagnoseButton" Content="Диагностика" Height="36" Padding="14,0" Margin="0,0,8,6"/>
                    <Button Name="RollbackButton" Content="Откатить последнее" Height="36" Padding="14,0" Margin="0,0,8,6" Background="#475467" Foreground="White" BorderThickness="0"/>
                    <TextBlock Name="ActionStatus" VerticalAlignment="Center" Margin="10,0,0,6" Foreground="#475467"/>
                </WrapPanel>
            </Grid>
        </Border>

        <Border Grid.Row="4" Background="#101828" CornerRadius="10" Padding="10">
            <TextBox Name="LogBox" IsReadOnly="True" AcceptsReturn="True" TextWrapping="Wrap"
                     VerticalScrollBarVisibility="Auto" Background="Transparent" Foreground="#D0D5DD"
                     BorderThickness="0" FontFamily="Consolas" FontSize="12"/>
        </Border>
    </Grid>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$names = @(
    'TargetTypeBox','ComputerBox','CredentialCheck','LinuxOptionsPanel','UseCurrentAccountCheck','LinuxUserBox','LinuxPortBox','LinuxKeyBox','BrowseLinuxKeyButton','ConnectButton','ConnectionStatus','SearchBox','StateFilter','GroupFilter',
    'SelectAllButton','ClearButton','RefreshButton','CollapseGroupsButton','ExpandGroupsButton','ExportButton','MonitorProcessesButton','CountText','ServicesGrid','MainTabs',
    'ServicesToolbar','ServiceActionPanel','StartButton','StopButton','RestartButton','RefreshServicesButton',
    'StartupTypeBox','SetStartupButton','DiagnoseButton','RollbackButton',
    'ProcessSearchBox','ProcessIntervalBox','ProcessMonitorButton','ProcessRefreshButton',
    'KillProcessButton','ProcessCountText','ProcessesGrid','ActionStatus','LogBox'
)
foreach ($name in $names) { Set-Variable -Name $name -Value $window.FindName($name) }

$script:AllServices = @()
$script:AllProcesses = @()
$script:Credential = $null
$script:ConnectedComputer = $null
$script:Session = $null
$script:TargetPlatform = 'Windows'
$script:LinuxUser = ''
$script:UseCurrentAccount = $true
$script:LinuxPort = 22
$script:LinuxKeyPath = ''
$script:LastSnapshotPath = $null
$script:ProcessRefreshActive = $false
$script:ProcessMonitoring = $false
$script:ProcessErrorCount = 0
$script:LinuxProcessSamples = @{}
$script:LinuxProcessSampleAt = $null
$script:ActiveSshProcess = $null
$script:ActiveWinRmJob = $null
$script:WindowsAuthentication = 'Kerberos'
$script:CoreProtectedWindowsServices = @(
    'RpcSs','RpcEptMapper','DcomLaunch','WinRM','EventLog','PlugPlay','Dhcp',
    'Dnscache','NlaSvc','LanmanWorkstation','SamSs','ProfSvc','Schedule',
    'CryptSvc','Netlogon'
)

$script:AppFolder = if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) { (Get-Location).Path } else { $PSScriptRoot }
$script:AppVersion = 'неизвестна'
$versionPath = Join-Path $script:AppFolder 'VERSION.txt'
if (Test-Path -LiteralPath $versionPath -PathType Leaf) {
    $versionMatch = [regex]::Match((Get-Content -LiteralPath $versionPath -Raw -Encoding UTF8), '(?m)^Version:\s*([0-9.]+)')
    if ($versionMatch.Success) { $script:AppVersion = $versionMatch.Groups[1].Value }
}
$window.Title = "Remote Service Manager $($script:AppVersion) — службы и процессы"
$script:DataFolder = if ($env:LOCALAPPDATA) {
    Join-Path $env:LOCALAPPDATA 'RemoteServiceManager'
} else {
    Join-Path $script:AppFolder 'data'
}
$script:SnapshotFolder = Join-Path $script:DataFolder 'snapshots'
$script:AuditPath = Join-Path $script:DataFolder 'operations.csv'
$script:ConfigPath = Join-Path $script:AppFolder 'service-groups.json'
try { [void](New-Item -ItemType Directory -Path $script:SnapshotFolder -Force -ErrorAction Stop) }
catch {
    [System.Windows.MessageBox]::Show("Не удалось создать папку рабочих данных:`n$($script:SnapshotFolder)`n`n$($_.Exception.Message)", 'Ошибка хранилища', 'OK', 'Error') | Out-Null
    return
}

$linuxBackendPath = Join-Path $script:AppFolder 'Linux-Remote.ps1'
if (-not (Test-Path -LiteralPath $linuxBackendPath -PathType Leaf)) {
    [System.Windows.MessageBox]::Show("Не найден модуль Linux-Remote.ps1.", 'Ошибка комплекта', 'OK', 'Error') | Out-Null
    return
}
. $linuxBackendPath

try {
    $script:Config = Get-Content -LiteralPath $script:ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    if ($script:Config.schemaVersion -ne 2) {
        throw 'Неподдерживаемая версия структуры конфигурации. Ожидается schemaVersion 2.'
    }
    if (@($script:Config.groups).Count -eq 0) {
        throw 'В конфигурации отсутствует список groups.'
    }
    foreach ($group in @($script:Config.groups)) {
        if ([string]::IsNullOrWhiteSpace([string]$group.name) -or @($group.patterns).Count -eq 0) {
            throw 'Каждая группа должна содержать имя и хотя бы одну маску.'
        }
    }
    if (@($script:Config.protectedServices).Count -eq 0) {
        throw 'В конфигурации отсутствует список protectedServices.'
    }
}
catch {
    [System.Windows.MessageBox]::Show("Не удалось загрузить service-groups.json.`n`n$($_.Exception.Message)", 'Ошибка конфигурации', 'OK', 'Error') | Out-Null
    return
}

$processTimer = New-Object System.Windows.Threading.DispatcherTimer
$processTimer.Interval = [TimeSpan]::FromSeconds(5)

function Write-Log {
    param([string]$Message)
    $LogBox.AppendText("[$(Get-Date -Format 'HH:mm:ss')] $Message`r`n")
    $LogBox.ScrollToEnd()
}

function Get-CurrentLinuxLoginName {
    # SSSD/realmd обычно принимает UPN вида user@domain. whoami /upn возвращает
    # именно UPN текущей интерактивной доменной учётной записи Windows.
    try {
        $upn = (& whoami.exe /upn 2>$null | Select-Object -First 1).Trim()
        if ($upn -match '^[^\s@]+@[^\s@]+$') { return $upn }
    }
    catch { }

    if ($env:USERNAME -and $env:USERDNSDOMAIN) {
        return ('{0}@{1}' -f $env:USERNAME, $env:USERDNSDOMAIN.ToLowerInvariant())
    }
    if ($env:USERNAME) { return $env:USERNAME }
    throw 'Не удалось определить имя текущей учётной записи Windows.'
}

function Test-WindowsTargetName {
    param([Parameter(Mandatory)][string]$Computer)

    $parsedAddress = $null
    $isIpAddress = [System.Net.IPAddress]::TryParse($Computer, [ref]$parsedAddress)
    $dnsLabel = '[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
    $isDnsName = $Computer.Length -le 253 -and $Computer -match "^(?:$dnsLabel\.)*$dnsLabel$"
    if ($isIpAddress -or -not $isDnsName) {
        throw 'Для Windows укажите DNS-имя компьютера, например R78-191036-W01. IP-адрес не используется: Kerberos не может проверить сервер по IP.'
    }
}

function Update-LinuxAccountUi {
    $useCurrent = $UseCurrentAccountCheck.IsChecked -eq $true
    $LinuxUserBox.IsEnabled = -not $useCurrent
    if ($useCurrent) {
        try { $LinuxUserBox.Text = Get-CurrentLinuxLoginName }
        catch { $LinuxUserBox.Text = '' }
    }
}

function ConvertTo-SafeCsvRecord {
    param(
        [Parameter(Mandatory)][object]$InputObject,
        [string[]]$ExcludeProperty = @()
    )

    $record = [ordered]@{}
    foreach ($property in $InputObject.PSObject.Properties) {
        if ($property.Name -in $ExcludeProperty) { continue }
        $value = $property.Value
        if ($value -is [string] -and $value -match '^\s*[=+\-@]') {
            $value = "'$value"
        }
        $record[$property.Name] = $value
    }
    return [pscustomobject]$record
}

function Write-Audit {
    param(
        [string]$Operation,
        [string]$Target,
        [string]$Before,
        [string]$After,
        [string]$Result,
        [string]$ErrorText = ''
    )
    try {
        $row = [pscustomobject]@{
            DateTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            Computer = $script:ConnectedComputer
            Operation = $Operation
            Target = $Target
            Before = $Before
            After = $After
            Result = $Result
            Error = $ErrorText
        }
        ConvertTo-SafeCsvRecord -InputObject $row |
            Export-Csv -LiteralPath $script:AuditPath -Delimiter ';' -NoTypeInformation -Encoding UTF8 -Append -ErrorAction Stop
    }
    catch {
        Write-Log "ПРЕДУПРЕЖДЕНИЕ: не удалось записать журнал операций — $($_.Exception.Message)"
    }
}

function Show-OperationResultWindow {
    param(
        [string]$ActionTitle,
        [array]$Results
    )
    $items = @($Results)
    if ($items.Count -eq 0) { return }
    $successCount = @($items | Where-Object Success).Count
    $errorCount = $items.Count - $successCount
    $warningCount = @($items | Where-Object { $_.Warning }).Count
    $timestamp = Get-Date -Format 'dd.MM.yyyy HH:mm:ss'

    $resultWindow = New-Object System.Windows.Window
    $resultWindow.Title = "Результат — $ActionTitle"
    $resultWindow.Width = 820
    $resultWindow.Height = 620
    $resultWindow.MinWidth = 650
    $resultWindow.MinHeight = 420
    $resultWindow.WindowStartupLocation = 'CenterOwner'
    $resultWindow.Owner = $window
    $resultWindow.Background = [System.Windows.Media.Brushes]::White

    $rootPanel = New-Object System.Windows.Controls.DockPanel
    $rootPanel.Margin = 16

    $headerPanel = New-Object System.Windows.Controls.StackPanel
    $headerPanel.Margin = '0,0,0,12'
    [System.Windows.Controls.DockPanel]::SetDock($headerPanel, 'Top')

    $titleBlock = New-Object System.Windows.Controls.TextBlock
    $titleBlock.Text = $ActionTitle
    $titleBlock.FontSize = 20
    $titleBlock.FontWeight = 'SemiBold'
    $titleBlock.Foreground = '#101828'
    [void]$headerPanel.Children.Add($titleBlock)

    $summaryBlock = New-Object System.Windows.Controls.TextBlock
    $summaryBlock.Text = "Компьютер: $($script:ConnectedComputer)    Время: $timestamp`nВсего: $($items.Count)    Успешно: $successCount    Предупреждений: $warningCount    Ошибок: $errorCount"
    $summaryBlock.Margin = '0,6,0,0'
    $summaryBlock.Foreground = '#475467'
    [void]$headerPanel.Children.Add($summaryBlock)
    [void]$rootPanel.Children.Add($headerPanel)

    $buttons = New-Object System.Windows.Controls.StackPanel
    $buttons.Orientation = 'Horizontal'
    $buttons.HorizontalAlignment = 'Right'
    $buttons.Margin = '0,12,0,0'
    [System.Windows.Controls.DockPanel]::SetDock($buttons, 'Bottom')

    $copyButton = New-Object System.Windows.Controls.Button
    $copyButton.Content = 'Копировать'
    $copyButton.Height = 34
    $copyButton.Padding = '16,0'
    $copyButton.Margin = '0,0,8,0'
    [void]$buttons.Children.Add($copyButton)

    $saveButton = New-Object System.Windows.Controls.Button
    $saveButton.Content = 'Сохранить отчёт'
    $saveButton.Height = 34
    $saveButton.Padding = '16,0'
    $saveButton.Margin = '0,0,8,0'
    [void]$buttons.Children.Add($saveButton)

    $closeButton = New-Object System.Windows.Controls.Button
    $closeButton.Content = 'Закрыть'
    $closeButton.Height = 34
    $closeButton.Padding = '20,0'
    $closeButton.Background = '#1769E0'
    $closeButton.Foreground = [System.Windows.Media.Brushes]::White
    $closeButton.BorderThickness = 0
    [void]$buttons.Children.Add($closeButton)
    [void]$rootPanel.Children.Add($buttons)

    $reportBox = New-Object System.Windows.Controls.RichTextBox
    $reportBox.IsReadOnly = $true
    $reportBox.FontFamily = 'Consolas'
    $reportBox.FontSize = 13
    $reportBox.Background = '#101828'
    $reportBox.Foreground = '#D0D5DD'
    $reportBox.BorderThickness = 0
    $reportBox.VerticalScrollBarVisibility = 'Auto'
    $reportBox.Padding = 12

    $document = New-Object System.Windows.Documents.FlowDocument
    $plainLines = New-Object System.Collections.Generic.List[string]
    [void]$plainLines.Add("Действие: $ActionTitle")
    [void]$plainLines.Add("Компьютер: $($script:ConnectedComputer)")
    [void]$plainLines.Add("Время: $timestamp")
    [void]$plainLines.Add("Всего: $($items.Count); успешно: $successCount; предупреждений: $warningCount; ошибок: $errorCount")
    [void]$plainLines.Add('')

    foreach ($item in $items) {
        $paragraph = New-Object System.Windows.Documents.Paragraph
        $paragraph.Margin = '0,1,0,1'
        if ($item.Success) {
            $details = if ($item.State) { $item.State } elseif ($item.StartMode) { $item.StartMode } else { 'выполнено' }
            $line = "УСПЕШНО — $($item.Name) — $details"
            $run = New-Object System.Windows.Documents.Run -ArgumentList $line
            $run.Foreground = '#32D583'
        }
        else {
            $line = "ОШИБКА — $($item.Name) — $($item.Error)"
            $run = New-Object System.Windows.Documents.Run -ArgumentList $line
            $run.Foreground = '#F97066'
        }
        [void]$plainLines.Add($line)
        [void]$paragraph.Inlines.Add($run)
        [void]$document.Blocks.Add($paragraph)
        if ($item.Warning) {
            $warningLine = "ПРЕДУПРЕЖДЕНИЕ — $($item.Name) — $($item.Warning)"
            $warningParagraph = New-Object System.Windows.Documents.Paragraph
            $warningParagraph.Margin = '18,1,0,3'
            $warningRun = New-Object System.Windows.Documents.Run -ArgumentList $warningLine
            $warningRun.Foreground = '#FEC84B'
            [void]$plainLines.Add($warningLine)
            [void]$warningParagraph.Inlines.Add($warningRun)
            [void]$document.Blocks.Add($warningParagraph)
        }
    }
    $reportBox.Document = $document
    [void]$rootPanel.Children.Add($reportBox)
    $resultWindow.Content = $rootPanel

    $plainText = $plainLines -join "`r`n"
    $copyButton.Tag = $plainText
    $copyButton.Add_Click({
        param($sender, $eventArgs)
        [System.Windows.Clipboard]::SetText([string]$sender.Tag)
    })
    $saveButton.Tag = $plainText
    $saveButton.Add_Click({
        param($sender, $eventArgs)
        $dialog = New-Object Microsoft.Win32.SaveFileDialog
        $dialog.Filter = 'Текстовый отчёт (*.txt)|*.txt'
        $safeComputer = $script:ConnectedComputer -replace '[^a-zA-Z0-9._-]', '_'
        $dialog.FileName = "Service_Result_${safeComputer}_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
        $ownerWindow = [System.Windows.Window]::GetWindow($sender)
        if ($dialog.ShowDialog($ownerWindow)) { Set-Content -LiteralPath $dialog.FileName -Value ([string]$sender.Tag) -Encoding UTF8 }
    })
    $closeButton.Add_Click({ param($sender, $eventArgs); [System.Windows.Window]::GetWindow($sender).Close() })
    [void]$resultWindow.ShowDialog()
}

function Set-Busy {
    param([bool]$Busy, [string]$Text = '')
    $hasConnection = -not $Busy -and -not [string]::IsNullOrWhiteSpace($script:ConnectedComputer)
    $hasServices = $hasConnection -and $script:AllServices.Count -gt 0
    $window.Cursor = if ($Busy) { [System.Windows.Input.Cursors]::Wait } else { $null }
    $TargetTypeBox.IsEnabled = -not $Busy
    $BrowseLinuxKeyButton.IsEnabled = -not $Busy
    $ConnectButton.IsEnabled = -not $Busy
    $RefreshButton.IsEnabled = $hasConnection
    $RefreshServicesButton.IsEnabled = $hasConnection
    $StartButton.IsEnabled = $hasServices
    $StopButton.IsEnabled = $hasServices
    $RestartButton.IsEnabled = $hasServices
    $SetStartupButton.IsEnabled = $hasServices
    $DiagnoseButton.IsEnabled = $hasServices
    $RollbackButton.IsEnabled = $hasConnection
    $MonitorProcessesButton.IsEnabled = $hasConnection
    $ProcessMonitorButton.IsEnabled = $hasConnection
    $ProcessRefreshButton.IsEnabled = $hasConnection
    $KillProcessButton.IsEnabled = $hasConnection -and $script:AllProcesses.Count -gt 0
    $ActionStatus.Text = $Text
}

function Reset-ProcessMonitorUi {
    $processTimer.Stop()
    $script:ProcessMonitoring = $false
    $script:ProcessRefreshActive = $false
    $script:ProcessErrorCount = 0
    $script:LinuxProcessSamples = @{}
    $script:LinuxProcessSampleAt = $null
    $ProcessMonitorButton.Content = '▶ Мониторинг'
    $ProcessMonitorButton.Background = '#1769E0'
}

function Clear-ConnectionState {
    Reset-ProcessMonitorUi
    if ($null -ne $script:ActiveWinRmJob -and $script:ActiveWinRmJob.State -in @('NotStarted','Running')) {
        Stop-Job -Job $script:ActiveWinRmJob -ErrorAction SilentlyContinue
    }
    if ($null -ne $script:ActiveSshProcess -and -not $script:ActiveSshProcess.HasExited) {
        try { $script:ActiveSshProcess.Kill() } catch { }
    }
    if ($null -ne $script:Session) {
        Remove-PSSession -Session $script:Session -ErrorAction SilentlyContinue
        $script:Session = $null
    }
    $script:ConnectedComputer = $null
    $script:Credential = $null
    $script:AllServices = @()
    $script:AllProcesses = @()
    Update-Grid
    Update-ProcessGrid
    Set-Busy $false
}

function Update-TargetModeUi {
    $platform = ([System.Windows.Controls.ComboBoxItem]$TargetTypeBox.SelectedItem).Content.ToString()
    $script:TargetPlatform = $platform
    $isLinux = $platform -eq 'Linux'
    $LinuxOptionsPanel.Visibility = if ($isLinux) { 'Visible' } else { 'Collapsed' }
    $CredentialCheck.Visibility = if ($isLinux) { 'Collapsed' } else { 'Visible' }
    if ($isLinux) { Update-LinuxAccountUi }
    if ($ProcessesGrid.Columns.Count -ge 8) {
        $ProcessesGrid.Columns[5].Visibility = if ($isLinux) { 'Collapsed' } else { 'Visible' }
        $ProcessesGrid.Columns[7].Visibility = if ($isLinux) { 'Collapsed' } else { 'Visible' }
    }
    $StartupTypeBox.Items.Clear()
    $startupTypes = if ($isLinux) { @('Automatic','Manual','Disabled') } else { @('Automatic','Automatic (Delayed)','Manual','Disabled') }
    foreach ($startupType in $startupTypes) {
        $item = New-Object System.Windows.Controls.ComboBoxItem
        $item.Content = $startupType
        [void]$StartupTypeBox.Items.Add($item)
    }
    $StartupTypeBox.SelectedIndex = 0
    $ConnectionStatus.Text = 'Не подключено'
    $ConnectionStatus.Foreground = '#667085'
}

function Get-RemoteParameters {
    if ($null -eq $script:Session -or $script:Session.State -ne 'Opened') {
        if ([string]::IsNullOrWhiteSpace($script:ConnectedComputer)) {
            throw 'Удалённая сессия отсутствует. Нажмите «Подключиться».'
        }
        Write-Log 'Удалённая сессия разорвана. Выполняется автоматическое переподключение...'
        Connect-RemoteSession -Computer $script:ConnectedComputer
        Write-Log 'Удалённая сессия восстановлена.'
    }
    return @{ Session = $script:Session; ErrorAction = 'Stop' }
}

function Invoke-RemoteCommand {
    param(
        [Parameter(Mandatory)][hashtable]$Parameters,
        [Parameter(Mandatory)][scriptblock]$ScriptBlock,
        [object[]]$ArgumentList = @(),
        [ValidateRange(5,300)][int]$TimeoutSeconds = 60
    )
    if ($null -ne $script:ActiveWinRmJob -and $script:ActiveWinRmJob.State -in @('NotStarted','Running')) {
        throw 'Другая WinRM-операция ещё выполняется.'
    }
    $invokeParameters = @{}
    foreach ($key in $Parameters.Keys) { $invokeParameters[$key] = $Parameters[$key] }
    $invokeParameters.ScriptBlock = $ScriptBlock
    $invokeParameters.AsJob = $true
    if ($ArgumentList.Count -gt 0) { $invokeParameters.ArgumentList = $ArgumentList }
    $job = Invoke-Command @invokeParameters
    $script:ActiveWinRmJob = $job
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    try {
        while ($job.State -in @('NotStarted','Running')) {
            if ([DateTime]::UtcNow -ge $deadline) {
                Stop-Job -Job $job -ErrorAction SilentlyContinue
                throw "WinRM-команда превысила тайм-аут $TimeoutSeconds сек."
            }
            $window.Dispatcher.Invoke([Action]{}, [Windows.Threading.DispatcherPriority]::Background)
            Start-Sleep -Milliseconds 50
        }
        if ($job.State -ne 'Completed') {
            $reason = [string]$job.ChildJobs[0].JobStateInfo.Reason
            if (-not $reason) { $reason = "Состояние задания: $($job.State)." }
            throw $reason
        }
        return @(Receive-Job -Job $job -ErrorAction Stop)
    }
    finally {
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
        $script:ActiveWinRmJob = $null
    }
}

function Connect-RemoteSession {
    param([string]$Computer)
    if ($null -ne $script:Session) {
        Remove-PSSession -Session $script:Session -ErrorAction SilentlyContinue
        $script:Session = $null
    }
    Test-WindowsTargetName -Computer $Computer
    $parameters = @{
        ComputerName = $Computer
        Authentication = $script:WindowsAuthentication
        ErrorAction = 'Stop'
    }
    if ($null -ne $script:Credential) { $parameters.Credential = $script:Credential }
    $option = New-PSSessionOption -OpenTimeout 15000 -OperationTimeout 30000 -IdleTimeout 1800000 -NoMachineProfile
    $parameters.SessionOption = $option
    $script:Session = New-PSSession @parameters
}

function Get-ServiceGroup {
    param([string]$Name, [string]$DisplayName, [string]$PathName)

    $values = @($Name, $DisplayName, $PathName)
    foreach ($group in $script:Config.groups) {
        foreach ($pattern in $group.patterns) {
            foreach ($value in $values) {
                if ($value -and $value -like $pattern) { return [string]$group.name }
            }
        }
    }
    return '10 — Прочие и системные службы'
}

function Set-GroupExpansionRecursive {
    param(
        [System.Windows.DependencyObject]$Parent,
        [bool]$Expanded
    )
    if ($null -eq $Parent) { return }
    $count = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($Parent)
    for ($index = 0; $index -lt $count; $index++) {
        $child = [System.Windows.Media.VisualTreeHelper]::GetChild($Parent, $index)
        if ($child -is [System.Windows.Controls.Expander] -and
            $child.DataContext -is [System.Windows.Data.CollectionViewGroup]) {
            $child.IsExpanded = $Expanded
        }
        Set-GroupExpansionRecursive -Parent $child -Expanded $Expanded
    }
}

function Set-AllGroupExpansion {
    param([bool]$Expanded)
    $ServicesGrid.UpdateLayout()
    Set-GroupExpansionRecursive -Parent $ServicesGrid -Expanded $Expanded
    Write-Log $(if ($Expanded) { 'Все группы развёрнуты.' } else { 'Все группы свёрнуты.' })
}

function Sync-GroupSelectorStates {
    param([System.Windows.DependencyObject]$Parent = $ServicesGrid)
    if ($null -eq $Parent) { return }
    $count = [System.Windows.Media.VisualTreeHelper]::GetChildrenCount($Parent)
    for ($index = 0; $index -lt $count; $index++) {
        $child = [System.Windows.Media.VisualTreeHelper]::GetChild($Parent, $index)
        if ($child -is [System.Windows.Controls.CheckBox] -and $child.Tag -eq 'GroupSelector') {
            $groupItems = @($child.DataContext.Items)
            $selectedCount = @($groupItems | Where-Object IsChecked).Count
            if ($selectedCount -eq 0) { $child.IsChecked = $false }
            elseif ($selectedCount -eq $groupItems.Count) { $child.IsChecked = $true }
            else { $child.IsChecked = $null }
        }
        Sync-GroupSelectorStates -Parent $child
    }
}

function Find-ParentCheckBox {
    param([System.Windows.DependencyObject]$Element)
    $current = $Element
    while ($null -ne $current) {
        if ($current -is [System.Windows.Controls.CheckBox]) { return $current }
        try { $parent = [System.Windows.Media.VisualTreeHelper]::GetParent($current) }
        catch { $parent = $null }
        if ($null -eq $parent) {
            try { $parent = [System.Windows.LogicalTreeHelper]::GetParent($current) }
            catch { $parent = $null }
        }
        $current = $parent
    }
    return $null
}

function Update-Grid {
    $query = $SearchBox.Text.Trim()
    $filter = ([System.Windows.Controls.ComboBoxItem]$StateFilter.SelectedItem).Content.ToString()
    $group = if ($null -ne $GroupFilter.SelectedItem) {
        ([System.Windows.Controls.ComboBoxItem]$GroupFilter.SelectedItem).Content.ToString()
    } else { 'Все группы' }

    $items = $script:AllServices
    if ($query) {
        $items = @($items | Where-Object {
            $_.Name -like "*$query*" -or $_.DisplayName -like "*$query*" -or $_.Description -like "*$query*"
        })
    }
    if ($filter -eq 'Запущенные') { $items = @($items | Where-Object State -eq 'Running') }
    if ($filter -eq 'Остановленные') { $items = @($items | Where-Object State -eq 'Stopped') }
    if ($filter -eq 'Ошибочные') { $items = @($items | Where-Object State -eq 'Failed') }
    if ($group -ne 'Все группы') { $items = @($items | Where-Object Group -eq $group) }

    # Числовой префикс группы задаёт порядок: 01 — EAS4, 02 — MARS, затем остальные.
    $items = @($items | Sort-Object Group, DisplayName)

    $ServicesGrid.ItemsSource = $null
    $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView(@($items))
    if ($null -ne $view -and $view.CanGroup) {
        $view.GroupDescriptions.Clear()
        $view.GroupDescriptions.Add((New-Object System.Windows.Data.PropertyGroupDescription 'Group'))
    }
    $ServicesGrid.ItemsSource = $view
    $CountText.Text = "Показано: $($items.Count) из $($script:AllServices.Count)"
    $ServicesGrid.UpdateLayout()
    Sync-GroupSelectorStates
}

function Update-ProcessGrid {
    $query = $ProcessSearchBox.Text.Trim()
    $items = $script:AllProcesses
    if ($query) {
        $items = @($items | Where-Object {
            $_.Name -like "*$query*" -or $_.ProcessId.ToString() -eq $query
        })
    }
    $items = @($items | Sort-Object CpuPercent, MemoryMB -Descending)
    $ProcessesGrid.ItemsSource = $null
    $ProcessesGrid.ItemsSource = $items
    $ProcessCountText.Text = "Показано: $($items.Count) из $($script:AllProcesses.Count)"
    $KillProcessButton.IsEnabled = -not [string]::IsNullOrWhiteSpace($script:ConnectedComputer) -and $script:AllProcesses.Count -gt 0
}

function Load-Processes {
    param([switch]$Quiet)
    if (-not $script:ConnectedComputer -or $script:ProcessRefreshActive) { return }
    $script:ProcessRefreshActive = $true
    try {
        $checkedPids = @($script:AllProcesses | Where-Object IsChecked | ForEach-Object ProcessId)
        if ($script:TargetPlatform -eq 'Linux') {
            $result = @(Get-LinuxProcessInventory)
        }
        else {
            $parameters = Get-RemoteParameters
            $result = Invoke-RemoteCommand -Parameters $parameters -ScriptBlock {
                $logicalProcessors = [Math]::Max(1, [int](Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors)
                $processInfo = @{}
                foreach ($item in @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)) {
                    $created = if ($item.CreationDate) { ([DateTime]$item.CreationDate).ToUniversalTime().ToString('o') } else { '' }
                    $processInfo[[int]$item.ProcessId] = [pscustomobject]@{ Name=$item.Name; Created=$created }
                }
                Get-CimInstance Win32_PerfFormattedData_PerfProc_Process |
                    Where-Object { $_.IDProcess -gt 0 -and $_.Name -notin @('_Total','Idle') } |
                    ForEach-Object {
                        $identity = $processInfo[[int]$_.IDProcess]
                        [pscustomobject]@{
                            Name        = ($_.Name -replace '#\d+$','')
                            ProcessId   = [int]$_.IDProcess
                            StartIdentity = if ($identity) { $identity.Created } else { '' }
                            CpuPercent  = [Math]::Round([Math]::Min(100, ([double]$_.PercentProcessorTime / $logicalProcessors)), 1)
                            MemoryMB    = [Math]::Round(([double]$_.WorkingSetPrivate / 1MB), 1)
                            DiskMBps    = [Math]::Round(([double]$_.IODataBytesPersec / 1MB), 2)
                            ThreadCount = [int]$_.ThreadCount
                            HandleCount = [int]$_.HandleCount
                        }
                    }
            }
        }
        $script:AllProcesses = @($result | ForEach-Object {
            [pscustomobject]@{
                IsChecked   = ($checkedPids -contains [int]$_.ProcessId)
                Name        = $_.Name
                ProcessId   = [int]$_.ProcessId
                StartIdentity = [string]$_.StartIdentity
                CpuPercent  = $_.CpuPercent
                MemoryMB    = $_.MemoryMB
                DiskMBps    = $_.DiskMBps
                ThreadCount = $_.ThreadCount
                HandleCount = $_.HandleCount
            }
        })
        $script:ProcessErrorCount = 0
        Update-ProcessGrid
    }
    catch {
        if ($Quiet) {
            $script:ProcessErrorCount++
            if ($script:ProcessErrorCount -eq 1) { Write-Log "ОШИБКА АВТООБНОВЛЕНИЯ ПРОЦЕССОВ: $($_.Exception.Message)" }
            if ($script:ProcessErrorCount -ge 3) {
                Reset-ProcessMonitorUi
                Write-Log 'Мониторинг остановлен после трёх последовательных ошибок подключения.'
            }
        }
        else {
            Write-Log "ОШИБКА МОНИТОРИНГА: $($_.Exception.Message)"
            [System.Windows.MessageBox]::Show("Не удалось получить список процессов.`n`n$($_.Exception.Message)", 'Ошибка', 'OK', 'Error') | Out-Null
        }
    }
    finally { $script:ProcessRefreshActive = $false }
}

function Stop-SelectedProcesses {
    $selected = @($script:AllProcesses | Where-Object IsChecked)
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show('Отметьте хотя бы один процесс флажком.', 'Нет выбранных процессов', 'OK', 'Information') | Out-Null
        return
    }

    $protectedNames = if ($script:TargetPlatform -eq 'Linux') {
        @('systemd','kthreadd','sshd','ssh','dbus-daemon','dbus-broker','systemd-logind',
          'systemd-udevd','networkmanager','sssd','winbindd','polkitd')
    } else {
        @('system','registry','smss','csrss','wininit','services','lsass','winlogon','svchost','wsmprovhost','powershell','pwsh')
    }
    $blocked = @($selected | Where-Object { $_.ProcessId -le 4 -or $_.Name.ToLowerInvariant() -in $protectedNames })
    $allowed = @($selected | Where-Object { $_.ProcessId -gt 4 -and $_.Name.ToLowerInvariant() -notin $protectedNames })
    if ($blocked.Count -gt 0) {
        Write-Log "ЗАЩИТА: пропущено системных процессов: $($blocked.Count)."
        foreach ($item in $blocked) {
            Write-Audit -Operation 'StopProcess' -Target "$($item.Name) [$($item.ProcessId)]" -Before 'Running' -After '' -Result 'Blocked' -ErrorText 'Защищённый системный процесс.'
        }
    }
    if ($allowed.Count -eq 0) {
        [System.Windows.MessageBox]::Show('Все выбранные процессы защищены от удалённого завершения.', 'Операция заблокирована', 'OK', 'Warning') | Out-Null
        return
    }

    $preview = ($allowed | Select-Object -First 15 | ForEach-Object { "• $($_.Name) (PID $($_.ProcessId))" }) -join "`n"
    if ($allowed.Count -gt 15) { $preview += "`n• ...и ещё $($allowed.Count - 15)" }
    $answer = [System.Windows.MessageBox]::Show(
        "Завершить выбранные процессы ($($allowed.Count))?`n`n$preview`n`nНесохранённые данные этих программ могут быть потеряны.",
        'Подтверждение завершения', 'YesNo', 'Warning')
    if ($answer -ne 'Yes') { return }

    try {
        if ($script:TargetPlatform -eq 'Linux') {
            $results = @(Stop-LinuxProcessBatch -Processes $allowed)
            foreach ($result in $results) {
                if ($result.Success) {
                    Write-Log "ГОТОВО: завершён Linux-процесс $($result.Name), PID $($result.ProcessId)."
                    Write-Audit -Operation 'StopProcess' -Target "$($result.Name) [$($result.ProcessId)]" -Before 'Running' -After 'Stopped' -Result 'Success'
                }
                else {
                    Write-Log "ОШИБКА: PID $($result.ProcessId) — $($result.Error)"
                    Write-Audit -Operation 'StopProcess' -Target "$($result.Name) [$($result.ProcessId)]" -Before 'Running' -After '' -Result 'Failed' -ErrorText $result.Error
                }
            }
            Load-Processes
            Show-OperationResultWindow -ActionTitle 'Завершение процессов Linux' -Results $results
            return
        }
        $parameters = Get-RemoteParameters
        $processesJson = @($allowed | Select-Object ProcessId,Name,StartIdentity) | ConvertTo-Json -Compress
        $results = Invoke-RemoteCommand -Parameters $parameters -ArgumentList @($processesJson) -ScriptBlock {
            param([string]$ProcessesJson)
            foreach ($expected in @(ConvertFrom-Json $ProcessesJson)) {
                $processId = [int]$expected.ProcessId
                try {
                    $info = Get-CimInstance Win32_Process -Filter "ProcessId=$processId" -ErrorAction Stop
                    if ($null -eq $info) { throw 'Процесс уже завершён.' }
                    $actualName = [IO.Path]::GetFileNameWithoutExtension([string]$info.Name)
                    $actualStart = if ($info.CreationDate) { ([DateTime]$info.CreationDate).ToUniversalTime().ToString('o') } else { '' }
                    if ($actualName -ne [string]$expected.Name -or
                        ($expected.StartIdentity -and $actualStart -ne [string]$expected.StartIdentity)) {
                        throw 'PID уже принадлежит другому процессу; завершение отменено.'
                    }
                    $process = Get-Process -Id $processId -ErrorAction Stop
                    $name = $actualName
                    Stop-Process -InputObject $process -Force -ErrorAction Stop
                    [pscustomobject]@{ ProcessId=$processId; Name=$name; Success=$true; Warning=''; Error='' }
                }
                catch {
                    [pscustomobject]@{ ProcessId=$processId; Name=[string]$expected.Name; Success=$false; Warning=''; Error=$_.Exception.Message }
                }
            }
        }
        foreach ($result in $results) {
            if ($result.Success) {
                Write-Log "ГОТОВО: завершён процесс $($result.Name), PID $($result.ProcessId)."
                Write-Audit -Operation 'StopProcess' -Target "$($result.Name) [$($result.ProcessId)]" -Before 'Running' -After 'Stopped' -Result 'Success'
            }
            else {
                Write-Log "ОШИБКА: PID $($result.ProcessId) — $($result.Error)"
                Write-Audit -Operation 'StopProcess' -Target "$($result.Name) [$($result.ProcessId)]" -Before 'Running' -After '' -Result 'Failed' -ErrorText $result.Error
            }
        }
        Load-Processes
        Show-OperationResultWindow -ActionTitle 'Завершение процессов' -Results @($results)
    }
    catch { Write-Log "ОШИБКА ЗАВЕРШЕНИЯ ПРОЦЕССА: $($_.Exception.Message)" }
}

function Test-IsProtectedService {
    param([string]$Name)
    if ($script:TargetPlatform -eq 'Linux') {
        $linuxProtected = @(
            'ssh.service','sshd.service','dbus.service','systemd-logind.service',
            'dbus-broker.service','systemd-networkd.service','NetworkManager.service',
            'NetworkManager-dispatcher.service','network.service','systemd-resolved.service',
            'systemd-udevd.service','polkit.service','sssd.service','winbind.service'
        )
        return $Name -in $linuxProtected
    }
    if ($Name -in $script:CoreProtectedWindowsServices) { return $true }
    return @($script:Config.protectedServices | Where-Object { $_ -eq $Name }).Count -gt 0
}

function Save-ServiceSnapshot {
    param([array]$Services, [string]$Reason)
    if ($Services.Count -eq 0) { return $null }
    $safeComputer = $script:ConnectedComputer -replace '[^a-zA-Z0-9._-]', '_'
    $safePlatform = $script:TargetPlatform -replace '[^a-zA-Z0-9._-]', '_'
    $path = Join-Path $script:SnapshotFolder ("snapshot_{0}_{1}_{2}.json" -f $safePlatform, $safeComputer, (Get-Date -Format 'yyyyMMdd_HHmmss_fff'))
    [pscustomobject]@{
        Version = 1
        Created = Get-Date -Format 'o'
        Computer = $script:ConnectedComputer
        Platform = $script:TargetPlatform
        Reason = $Reason
        Services = @($Services | Select-Object Name, DisplayName, State, StartMode, DelayedAutoStart)
    } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $path -Encoding UTF8
    $script:LastSnapshotPath = $path
    Write-Log "Создан снимок состояния: $([IO.Path]::GetFileName($path))."
    return $path
}

function Set-SelectedStartupType {
    $selected = @($script:AllServices | Where-Object IsChecked)
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show('Отметьте хотя бы одну службу.', 'Нет выбранных служб', 'OK', 'Information') | Out-Null
        return
    }
    $requested = ([System.Windows.Controls.ComboBoxItem]$StartupTypeBox.SelectedItem).Content.ToString()
    if ($requested -eq 'Disabled') {
        $protected = @($selected | Where-Object { Test-IsProtectedService $_.Name })
        if ($protected.Count -gt 0) {
            $names = ($protected.Name -join ', ')
            [System.Windows.MessageBox]::Show("Отключение защищённых служб запрещено:`n$names", 'Защита ядра', 'OK', 'Warning') | Out-Null
            return
        }
    }
    $answer = [System.Windows.MessageBox]::Show("Изменить тип запуска у $($selected.Count) служб на «$requested»?", 'Подтверждение', 'YesNo', 'Warning')
    if ($answer -ne 'Yes') { return }
    [void](Save-ServiceSnapshot -Services $selected -Reason "StartupType:$requested")
    Set-Busy $true 'Изменение типа запуска...'
    try {
        if ($script:TargetPlatform -eq 'Linux') {
            $beforeByName = @{}
            foreach ($service in $selected) { $beforeByName[$service.Name] = $service.StartMode }
            $linuxResult = Set-LinuxStartupType -Names @($selected.Name) -StartupType $requested
            $expectedMode = if ($requested -eq 'Automatic') { 'Auto' } else { $requested }
            $commandError = ($linuxResult.Output -join ' ').Trim()
            $results = @($linuxResult.Services | ForEach-Object {
                $actualMode = Convert-LinuxUnitFileState $_.UnitFileState
                $success = $actualMode -eq $expectedMode
                [pscustomobject]@{
                    Name=$_.Name; Success=$success; State=(Convert-LinuxActiveState $_.ActiveState)
                    BeforeStartMode=$beforeByName[$_.Name]; StartMode=$actualMode
                    Warning=if ($requested -eq 'Disabled' -and $_.ActiveState -eq 'active') { 'Служба продолжает работать до остановки или перезагрузки.' } else { '' }
                    Error=if ($success) { '' } elseif ($commandError) { $commandError } else { "Не удалось установить режим $requested." }
                }
            })
            foreach ($result in $results) {
                if ($result.Success) {
                    Write-Log "ГОТОВО: Linux-служба $($result.Name), тип запуска — $requested."
                    Write-Audit -Operation 'SetStartupType' -Target $result.Name -Before $result.BeforeStartMode -After $requested -Result 'Success'
                } else {
                    Write-Log "ОШИБКА: $($result.Name) — $($result.Error)"
                    Write-Audit -Operation 'SetStartupType' -Target $result.Name -Before $result.BeforeStartMode -After $requested -Result 'Failed' -ErrorText $result.Error
                }
            }
            Load-Services
            Show-OperationResultWindow -ActionTitle "Linux: тип запуска $requested" -Results $results
            return
        }
        $namesJson = @($selected.Name) | ConvertTo-Json -Compress
        $parameters = Get-RemoteParameters
        $results = Invoke-RemoteCommand -Parameters $parameters -ArgumentList @($namesJson,$requested) -ScriptBlock {
            param([string]$NamesJson,[string]$Requested)
            foreach ($name in @(ConvertFrom-Json $NamesJson)) {
                try {
                    $service = Get-Service -Name $name -ErrorAction Stop
                    $beforeInfo = Get-CimInstance Win32_Service -Filter "Name='$($name.Replace("'", "''"))'" -ErrorAction Stop
                    $startup = switch ($Requested) {
                        'Automatic' { 'Automatic' }
                        'Automatic (Delayed)' { 'Automatic' }
                        'Manual' { 'Manual' }
                        'Disabled' { 'Disabled' }
                    }
                    Set-Service -Name $name -StartupType $startup -ErrorAction Stop
                    $key = "HKLM:\SYSTEM\CurrentControlSet\Services\$name"
                    $delayedValue = [int]($Requested -eq 'Automatic (Delayed)')
                    New-ItemProperty -LiteralPath $key -Name DelayedAutoStart -PropertyType DWord -Value $delayedValue -Force -ErrorAction Stop | Out-Null
                    $info = Get-CimInstance Win32_Service -Filter "Name='$($name.Replace("'", "''"))'"
                    $warning = if ($Requested -eq 'Disabled' -and $service.Status -eq 'Running') { 'Служба продолжит работать до остановки или перезагрузки.' } else { '' }
                    [pscustomobject]@{Name=$name;Success=$true;State=$service.Status.ToString();BeforeStartMode=$beforeInfo.StartMode;StartMode=$info.StartMode;Warning=$warning;Error=''}
                } catch {
                    [pscustomobject]@{Name=$name;Success=$false;State='';BeforeStartMode='';StartMode='';Warning='';Error=$_.Exception.Message}
                }
            }
        }
        foreach ($result in $results) {
            if ($result.Success) {
                Write-Log "ГОТОВО: $($result.Name), тип запуска — $requested."
                Write-Audit -Operation 'SetStartupType' -Target $result.Name -Before $result.BeforeStartMode -After $requested -Result 'Success'
            } else {
                Write-Log "ОШИБКА: $($result.Name) — $($result.Error)"
                Write-Audit -Operation 'SetStartupType' -Target $result.Name -Before $result.BeforeStartMode -After $requested -Result 'Failed' -ErrorText $result.Error
            }
        }
        Load-Services
        Show-OperationResultWindow -ActionTitle "Изменение типа запуска: $requested" -Results @($results)
    } catch { Write-Log "ОШИБКА ИЗМЕНЕНИЯ ТИПА ЗАПУСКА: $($_.Exception.Message)" }
    finally { Set-Busy $false }
}

function Restore-LastSnapshot {
    $safeComputer = $script:ConnectedComputer -replace '[^a-zA-Z0-9._-]', '_'
    $safePlatform = $script:TargetPlatform -replace '[^a-zA-Z0-9._-]', '_'
    $latest = Get-ChildItem -LiteralPath $script:SnapshotFolder -Filter "snapshot_${safePlatform}_${safeComputer}_*.json" -File |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($null -eq $latest) {
        [System.Windows.MessageBox]::Show('Для подключённого компьютера снимки ещё не создавались.', 'Откат недоступен', 'OK', 'Information') | Out-Null
        return
    }
    $script:LastSnapshotPath = $latest.FullName
    $snapshot = Get-Content -LiteralPath $script:LastSnapshotPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($snapshot.Computer -ne $script:ConnectedComputer) {
        [System.Windows.MessageBox]::Show("Снимок относится к компьютеру $($snapshot.Computer), а подключение выполнено к $($script:ConnectedComputer).", 'Откат заблокирован', 'OK', 'Warning') | Out-Null
        return
    }
    $snapshotPlatform = if ($snapshot.PSObject.Properties.Name -contains 'Platform') { [string]$snapshot.Platform } else { 'Windows' }
    if ($snapshotPlatform -ne $script:TargetPlatform) {
        [System.Windows.MessageBox]::Show("Снимок создан для $snapshotPlatform, а текущее подключение — $($script:TargetPlatform).", 'Откат заблокирован', 'OK', 'Warning') | Out-Null
        return
    }
    $answer = [System.Windows.MessageBox]::Show("Восстановить состояние $(@($snapshot.Services).Count) служб из снимка?", 'Подтверждение отката', 'YesNo', 'Warning')
    if ($answer -ne 'Yes') { return }
    try {
        if ($script:TargetPlatform -eq 'Linux') {
            $operationErrors = New-Object System.Collections.Generic.List[string]
            foreach ($modeGroup in @($snapshot.Services | Group-Object StartMode)) {
                $requestedMode = if ($modeGroup.Name -eq 'Auto') { 'Automatic' } else { $modeGroup.Name }
                $modeResult = Set-LinuxStartupType -Names @($modeGroup.Group.Name) -StartupType $requestedMode
                if ($modeResult.ExitCode -ne 0) { $operationErrors.Add(($modeResult.Output -join ' ')) }
            }
            $runningNames = @($snapshot.Services | Where-Object State -eq 'Running' | ForEach-Object Name)
            $stoppedNames = @($snapshot.Services | Where-Object State -eq 'Stopped' | ForEach-Object Name)
            if ($runningNames.Count -gt 0) {
                $actionResult = Invoke-LinuxSystemctlAction -Names $runningNames -Action Start -Unmask $true
                if ($actionResult.ExitCode -ne 0) { $operationErrors.Add(($actionResult.Output -join ' ')) }
            }
            if ($stoppedNames.Count -gt 0) {
                $actionResult = Invoke-LinuxSystemctlAction -Names $stoppedNames -Action Stop
                if ($actionResult.ExitCode -ne 0) { $operationErrors.Add(($actionResult.Output -join ' ')) }
            }
            # Запуск ранее masked-службы требует временного unmask. После
            # восстановления состояния возвращаем маску, не останавливая службу.
            $maskedNames = @($snapshot.Services | Where-Object StartMode -eq 'Disabled' | ForEach-Object Name)
            if ($maskedNames.Count -gt 0) {
                $modeResult = Set-LinuxStartupType -Names $maskedNames -StartupType Disabled
                if ($modeResult.ExitCode -ne 0) { $operationErrors.Add(($modeResult.Output -join ' ')) }
            }
            $actualByName = @{}
            foreach ($item in @(Get-LinuxServiceInventory -Names @($snapshot.Services.Name))) { $actualByName[$item.Name] = $item }
            $errorText = ($operationErrors | Where-Object { $_ } | Select-Object -Unique) -join '; '
            $results = @($snapshot.Services | ForEach-Object {
                $expected = $_
                $actual = $actualByName[$expected.Name]
                $actualState = if ($actual) { Convert-LinuxActiveState $actual.ActiveState } else { '' }
                $actualMode = if ($actual) { Convert-LinuxUnitFileState $actual.UnitFileState } else { '' }
                $success = $actualState -eq $expected.State -and $actualMode -eq $expected.StartMode
                [pscustomobject]@{Name=$expected.Name;Success=$success;State=$actualState;StartMode=$actualMode;Warning='';Error=if ($success) { '' } else { $errorText }}
            })
            foreach ($result in $results) {
                if ($result.Success) { Write-Log "ОТКАТ Linux: $($result.Name) восстановлена."; Write-Audit -Operation 'Rollback' -Target $result.Name -Before '' -After 'Snapshot' -Result 'Success' }
                else { Write-Log "ОШИБКА ОТКАТА Linux: $($result.Name) — $($result.Error)"; Write-Audit -Operation 'Rollback' -Target $result.Name -Before '' -After 'Snapshot' -Result 'Failed' -ErrorText $result.Error }
            }
            Load-Services
            Show-OperationResultWindow -ActionTitle 'Откат состояния служб Linux' -Results $results
            return
        }
        $snapshotJson = @($snapshot.Services) | ConvertTo-Json -Depth 5 -Compress
        $parameters = Get-RemoteParameters
        $results = Invoke-RemoteCommand -Parameters $parameters -ArgumentList @($snapshotJson) -ScriptBlock {
            param([string]$SnapshotJson)
            foreach ($item in @(ConvertFrom-Json $SnapshotJson)) {
                try {
                    $startup = switch ($item.StartMode) {
                        'Auto' { 'Automatic' }
                        'Manual' { 'Manual' }
                        'Disabled' { 'Disabled' }
                        default { throw "Неизвестный тип запуска в снимке: $($item.StartMode)" }
                    }
                    Set-Service -Name $item.Name -StartupType $startup -ErrorAction Stop
                    $key = "HKLM:\SYSTEM\CurrentControlSet\Services\$($item.Name)"
                    New-ItemProperty -LiteralPath $key -Name DelayedAutoStart -PropertyType DWord -Value ([int][bool]$item.DelayedAutoStart) -Force -ErrorAction SilentlyContinue | Out-Null
                    $service = Get-Service -Name $item.Name -ErrorAction Stop
                    if ($item.State -eq 'Running' -and $service.Status -ne 'Running') { Start-Service $service -ErrorAction Stop }
                    if ($item.State -eq 'Stopped' -and $service.Status -ne 'Stopped') { Stop-Service $service -ErrorAction Stop }
                    [pscustomobject]@{Name=$item.Name;Success=$true;Error=''}
                } catch { [pscustomobject]@{Name=$item.Name;Success=$false;Error=$_.Exception.Message} }
            }
        }
        foreach ($result in $results) {
            if ($result.Success) { Write-Log "ОТКАТ: $($result.Name) восстановлена."; Write-Audit -Operation 'Rollback' -Target $result.Name -Before '' -After 'Snapshot' -Result 'Success' }
            else { Write-Log "ОШИБКА ОТКАТА: $($result.Name) — $($result.Error)"; Write-Audit -Operation 'Rollback' -Target $result.Name -Before '' -After 'Snapshot' -Result 'Failed' -ErrorText $result.Error }
        }
        Load-Services
        Show-OperationResultWindow -ActionTitle 'Откат состояния служб' -Results @($results)
    } catch { Write-Log "ОШИБКА ОТКАТА: $($_.Exception.Message)" }
}

function Diagnose-SelectedServices {
    $selected = @($script:AllServices | Where-Object IsChecked)
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show('Отметьте одну или несколько служб.', 'Нет выбранных служб', 'OK', 'Information') | Out-Null
        return
    }
    try {
        if ($script:TargetPlatform -eq 'Linux') {
            $diagnostic = Get-LinuxServiceDiagnostics -Names @($selected.Name)
            $diagnosticText = ($diagnostic.Output -join "`n").Trim()
            if ($diagnosticText) { Write-Log "ДИАГНОСТИКА Linux:`n$diagnosticText" }
            $success = [bool]$diagnosticText
            $results = @($selected | ForEach-Object {
                [pscustomobject]@{
                    Name=$_.Name; Success=$success; State=if ($success) { 'отчёт записан в журнал' } else { '' }
                    StartMode=$_.StartMode; Warning=''; Error=if ($success) { '' } else { 'systemctl и journalctl не вернули данные.' }
                }
            })
            Show-OperationResultWindow -ActionTitle 'Диагностика служб Linux' -Results $results
            return
        }
        $namesJson = @($selected.Name) | ConvertTo-Json -Compress
        $parameters = Get-RemoteParameters
        $results = Invoke-RemoteCommand -Parameters $parameters -ArgumentList @($namesJson) -ScriptBlock {
            param([string]$NamesJson)
            $serviceEvents = @(Get-WinEvent -FilterHashtable @{
                LogName = 'System'
                ProviderName = 'Service Control Manager'
                StartTime = (Get-Date).AddDays(-1)
            } -ErrorAction SilentlyContinue)
            foreach ($name in @(ConvertFrom-Json $NamesJson)) {
                $service = Get-Service -Name $name -ErrorAction SilentlyContinue
                $info = Get-CimInstance Win32_Service -Filter "Name='$($name.Replace("'", "''"))'" -ErrorAction SilentlyContinue
                $events = @($serviceEvents |
                    Where-Object { $_.Message -like "*$name*" } |
                    Select-Object -First 5 TimeCreated,Id,LevelDisplayName,Message)
                [pscustomobject]@{
                    Name=$name; State=$service.Status; StartMode=$info.StartMode; ExitCode=$info.ExitCode; Path=$info.PathName
                    DependsOn=@($service.ServicesDependedOn.Name) -join ', '
                    Dependents=@($service.DependentServices.Name) -join ', '
                    Events=@($events | ForEach-Object { "[$($_.TimeCreated)] ID $($_.Id): $($_.Message -replace '[\r\n]+',' ')" }) -join "`n"
                }
            }
        }
        foreach ($result in $results) {
            Write-Log "ДИАГНОСТИКА $($result.Name): состояние=$($result.State), запуск=$($result.StartMode), ExitCode=$($result.ExitCode)"
            Write-Log "  Зависит от: $(if ($result.DependsOn) {$result.DependsOn} else {'нет'})"
            Write-Log "  Зависимые службы: $(if ($result.Dependents) {$result.Dependents} else {'нет'})"
            Write-Log "  Путь: $($result.Path)"
            if ($result.Events) { Write-Log "  События за 24 часа:`n$($result.Events)" } else { Write-Log '  Ошибок Service Control Manager за 24 часа не найдено.' }
        }
    } catch { Write-Log "ОШИБКА ДИАГНОСТИКИ: $($_.Exception.Message)" }
}

function Load-Services {
    param([switch]$ThrowOnError)
    if (-not $script:ConnectedComputer) { return }
    Set-Busy $true 'Получение списка служб...'
    try {
        if ($script:TargetPlatform -eq 'Linux') {
            $result = @(Get-LinuxServiceInventory | ForEach-Object {
                [pscustomobject]@{
                    Name=$_.Name; DisplayName=$_.Description; Description=$_.Description
                    State=(Convert-LinuxActiveState $_.ActiveState); Status=$_.SubState
                    StartMode=(Convert-LinuxUnitFileState $_.UnitFileState); StartName=$(if ($_.User) { $_.User } else { 'root' })
                    ServiceType='systemd'; ProcessId=$_.MainPID; PathName=$_.FragmentPath
                    AcceptPause=$false; AcceptStop=$true; DesktopInteract=$false
                    ErrorControl=''; ExitCode=0; ServiceSpecificExitCode=0
                    Started=($_.ActiveState -eq 'active'); SystemName=$script:ConnectedComputer; DelayedAutoStart=$false
                }
            })
        }
        else {
            $parameters = Get-RemoteParameters
            $result = Invoke-RemoteCommand -Parameters $parameters -ScriptBlock {
                Get-CimInstance -ClassName Win32_Service | Sort-Object DisplayName | Select-Object `
                    Name, DisplayName, Description, State, Status, StartMode, StartName,
                    ServiceType, ProcessId, PathName, AcceptPause, AcceptStop, DesktopInteract,
                    ErrorControl, ExitCode, ServiceSpecificExitCode, Started, SystemName, DelayedAutoStart
            }
        }
        $script:AllServices = @($result | ForEach-Object {
            [pscustomobject]@{
                IsChecked = $false
                Group = Get-ServiceGroup -Name $_.Name -DisplayName $_.DisplayName -PathName $_.PathName
                Name = $_.Name
                DisplayName = $_.DisplayName
                Description = $_.Description
                State = $_.State
                Status = $_.Status
                StartMode = $_.StartMode
                StartName = $_.StartName
                ServiceType = $_.ServiceType
                ProcessId = $_.ProcessId
                PathName = $_.PathName
                AcceptPause = $_.AcceptPause
                AcceptStop = $_.AcceptStop
                DesktopInteract = $_.DesktopInteract
                ErrorControl = $_.ErrorControl
                ExitCode = $_.ExitCode
                ServiceSpecificExitCode = $_.ServiceSpecificExitCode
                Started = $_.Started
                SystemName = $_.SystemName
                DelayedAutoStart = [bool]$_.DelayedAutoStart
            }
        })
        $selectedGroup = if ($null -ne $GroupFilter.SelectedItem) {
            ([System.Windows.Controls.ComboBoxItem]$GroupFilter.SelectedItem).Content.ToString()
        } else { 'Все группы' }
        $GroupFilter.Items.Clear()
        $allGroupsItem = New-Object System.Windows.Controls.ComboBoxItem
        $allGroupsItem.Content = 'Все группы'
        [void]$GroupFilter.Items.Add($allGroupsItem)
        $preparedGroups = @($script:Config.groups.name) + @('10 — Прочие и системные службы')
        foreach ($groupName in $preparedGroups) {
            $item = New-Object System.Windows.Controls.ComboBoxItem
            $item.Content = $groupName
            [void]$GroupFilter.Items.Add($item)
        }
        $GroupFilter.SelectedIndex = 0
        for ($i = 0; $i -lt $GroupFilter.Items.Count; $i++) {
            if ($GroupFilter.Items[$i].Content.ToString() -eq $selectedGroup) { $GroupFilter.SelectedIndex = $i; break }
        }
        Update-Grid
        $ConnectionStatus.Text = "Подключено ($($script:TargetPlatform)): $($script:ConnectedComputer)"
        $ConnectionStatus.Foreground = '#16803C'
        Write-Log "Получен список служб: $($script:AllServices.Count)."
    }
    catch {
        $script:AllServices = @()
        Update-Grid
        $ConnectionStatus.Text = 'Ошибка подключения'
        $ConnectionStatus.Foreground = '#C62828'
        Write-Log "ОШИБКА: $($_.Exception.Message)"
        if ($ThrowOnError) { throw }
        [System.Windows.MessageBox]::Show("Не удалось получить службы.`n`n$($_.Exception.Message)", 'Ошибка', 'OK', 'Error') | Out-Null
    }
    finally { Set-Busy $false }
}

function Invoke-LinuxServiceAction {
    param([ValidateSet('Start','Stop','Restart')][string]$Action)
    $selected = @($script:AllServices | Where-Object IsChecked)
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show('Отметьте хотя бы одну службу флажком.', 'Нет выбранных служб', 'OK', 'Information') | Out-Null
        return
    }
    if ($Action -in @('Stop','Restart')) {
        $protected = @($selected | Where-Object { Test-IsProtectedService $_.Name })
        if ($protected.Count -gt 0) {
            [System.Windows.MessageBox]::Show("Операция заблокирована для критических Linux-служб:`n$($protected.Name -join ', ')", 'Защита ядра', 'OK', 'Warning') | Out-Null
            return
        }
    }
    $unmask = $false
    if ($Action -in @('Start','Restart') -and @($selected | Where-Object StartMode -eq 'Disabled').Count -gt 0) {
        $answer = [System.Windows.MessageBox]::Show('Среди выбранных служб есть masked. Снять маску и продолжить?', 'Отключённые Linux-службы', 'YesNo', 'Warning')
        if ($answer -ne 'Yes') { return }
        $unmask = $true
    }
    $actionText = @{Start='запустить';Stop='остановить';Restart='перезапустить'}[$Action]
    $answer = [System.Windows.MessageBox]::Show("Вы действительно хотите $actionText выбранные Linux-службы ($($selected.Count))?", 'Подтверждение операции', 'YesNo', 'Warning')
    if ($answer -ne 'Yes') { return }

    [void](Save-ServiceSnapshot -Services $selected -Reason $Action)
    Set-Busy $true "Linux: выполняется $actionText..."
    $operationTimer = [Diagnostics.Stopwatch]::StartNew()
    try {
        $beforeByName = @{}
        foreach ($service in $selected) { $beforeByName[$service.Name] = $service }
        $linuxResult = Invoke-LinuxSystemctlAction -Names @($selected.Name) -Action $Action -Unmask $unmask
        $actualByName = @{}
        foreach ($service in $linuxResult.Services) { $actualByName[$service.Name] = $service }
        $expectedState = if ($Action -eq 'Stop') { 'Stopped' } else { 'Running' }
        $commandError = ($linuxResult.Output -join ' ').Trim()
        $results = @($selected | ForEach-Object {
            $before = $_
            $actual = $actualByName[$before.Name]
            $state = if ($actual) { Convert-LinuxActiveState $actual.ActiveState } else { '' }
            $startMode = if ($actual) { Convert-LinuxUnitFileState $actual.UnitFileState } else { '' }
            $success = $state -eq $expectedState
            [pscustomobject]@{
                Name=$before.Name; Success=$success; State=$state; StartMode=$startMode
                ProcessId=if ($actual) { $actual.MainPID } else { 0 }
                StartupChanged=($unmask -and $before.StartMode -eq 'Disabled')
                BeforeState=$before.State; BeforeStartMode=$before.StartMode; Warning=''
                Error=if ($success) { '' } elseif ($commandError) { $commandError } else { "Служба не перешла в состояние $expectedState." }
            }
        })
        foreach ($result in $results) {
            if ($result.Success) {
                Write-Log "ГОТОВО Linux: $($result.Name) — состояние $($result.State)."
                Write-Audit -Operation $Action -Target $result.Name -Before "$($result.BeforeState)/$($result.BeforeStartMode)" -After "$($result.State)/$($result.StartMode)" -Result 'Success'
            } else {
                Write-Log "ОШИБКА Linux: $($result.Name) — $($result.Error)"
                Write-Audit -Operation $Action -Target $result.Name -Before "$($result.BeforeState)/$($result.BeforeStartMode)" -After "$($result.State)/$($result.StartMode)" -Result 'Failed' -ErrorText $result.Error
            }
        }
        foreach ($result in $results) {
            $local = $beforeByName[$result.Name]
            if ($result.State) { $local.State=$result.State; $local.Started=($result.State -eq 'Running') }
            if ($result.StartMode) { $local.StartMode=$result.StartMode }
            $local.ProcessId=$result.ProcessId; $local.IsChecked=$false
        }
        Update-Grid
        $operationTimer.Stop()
        Write-Log "Пакетная Linux-операция завершена за $([Math]::Round($operationTimer.Elapsed.TotalSeconds,1)) сек."
        Show-OperationResultWindow -ActionTitle "Linux: $actionText" -Results $results
    }
    catch {
        Write-Log "ОШИБКА Linux-операции: $($_.Exception.Message)"
        [System.Windows.MessageBox]::Show($_.Exception.Message, 'Ошибка Linux-операции', 'OK', 'Error') | Out-Null
    }
    finally {
        if ($operationTimer.IsRunning) { $operationTimer.Stop() }
        Set-Busy $false
    }
}

function Invoke-ServiceAction {
    param([ValidateSet('Start','Stop','Restart')][string]$Action)

    if ($script:TargetPlatform -eq 'Linux') {
        Invoke-LinuxServiceAction -Action $Action
        return
    }

    $selected = @($script:AllServices | Where-Object IsChecked)
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show('Отметьте хотя бы одну службу флажком.', 'Нет выбранных служб', 'OK', 'Information') | Out-Null
        return
    }

    if ($Action -in @('Stop','Restart')) {
        $protectedSelected = @($selected | Where-Object { Test-IsProtectedService $_.Name })
        if ($protectedSelected.Count -gt 0) {
            $protectedNames = $protectedSelected.Name -join ', '
            [System.Windows.MessageBox]::Show("Операция заблокирована для критических служб:`n$protectedNames`n`nИзмените protectedServices в service-groups.json только если понимаете последствия.", 'Защита ядра', 'OK', 'Warning') | Out-Null
            Write-Log "ЗАЩИТА: операция $Action заблокирована для: $protectedNames."
            return
        }
    }

    $actionText = @{
        Start='запустить'
        Stop='остановить'
        Restart='перезапустить'
    }[$Action]
    $enableDisabled = $false

    # Windows не разрешает запуск служб с типом запуска Disabled.
    # Предлагаем явно изменить их тип запуска на Manual.
    if ($Action -in @('Start','Restart')) {
        $disabledServices = @($selected | Where-Object StartMode -eq 'Disabled')
        if ($disabledServices.Count -gt 0) {
            $disabledPreview = ($disabledServices | Select-Object -First 10 | ForEach-Object {
                "• $($_.DisplayName) [$($_.Name)]"
            }) -join "`n"
            if ($disabledServices.Count -gt 10) {
                $disabledPreview += "`n• ...и ещё $($disabledServices.Count - 10)"
            }

            $disabledAnswer = [System.Windows.MessageBox]::Show(
                "Следующие службы отключены (Disabled) и не могут быть запущены:`n`n$disabledPreview`n`nИзменить их тип запуска на «Вручную» (Manual) и продолжить?",
                'Отключённые службы', 'YesNo', 'Warning')

            if ($disabledAnswer -ne 'Yes') {
                Write-Log 'Операция отменена: пользователь не разрешил включение отключённых служб.'
                return
            }
            $enableDisabled = $true
        }
    }

    $preview = ($selected | Select-Object -First 12 | ForEach-Object { "• $($_.DisplayName) [$($_.Name)]" }) -join "`n"
    if ($selected.Count -gt 12) { $preview += "`n• ...и ещё $($selected.Count - 12)" }
    $answer = [System.Windows.MessageBox]::Show(
        "Вы действительно хотите $actionText выбранные службы ($($selected.Count))?`n`n$preview",
        'Подтверждение операции', 'YesNo', 'Warning')
    if ($answer -ne 'Yes') { return }

    [void](Save-ServiceSnapshot -Services $selected -Reason $Action)

    Set-Busy $true "Выполняется: $actionText..."
    $operationTimer = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $parameters = Get-RemoteParameters

        # Массив нельзя надёжно передавать напрямую через -ArgumentList:
        # Windows PowerShell иногда объединяет несколько имён в одну строку.
        # JSON сохраняет каждое имя службы отдельным элементом.
        $serviceNamesJson = @($selected.Name) | ConvertTo-Json -Compress

        $results = Invoke-RemoteCommand -Parameters $parameters -ArgumentList @($serviceNamesJson,$Action,$enableDisabled) -ScriptBlock {
            param([string]$ServiceNamesJson, [string]$RequestedAction, [bool]$EnableDisabled)

            $ServiceNames = @(ConvertFrom-Json -InputObject $ServiceNamesJson)

            # Получаем контроллеры и сведения обо всех службах только один раз.
            $controllersByName = @{}
            foreach ($controller in @(Get-Service -Name $ServiceNames -ErrorAction SilentlyContinue)) {
                $controllersByName[$controller.Name] = $controller
            }
            $serviceFilter = @($ServiceNames | ForEach-Object {
                $escapedName = $_.Replace("'", "''")
                "Name='$escapedName'"
            }) -join ' OR '
            $infoByName = @{}
            foreach ($info in @(Get-CimInstance -ClassName Win32_Service -Filter $serviceFilter -ErrorAction Stop)) {
                $infoByName[$info.Name] = $info
            }

            $records = @{}
            foreach ($serviceName in $ServiceNames) {
                $controller = $controllersByName[$serviceName]
                $serviceInfo = $infoByName[$serviceName]
                $errorText = ''
                if ($null -eq $controller -or $null -eq $serviceInfo) {
                    $errorText = 'Служба не найдена.'
                }
                $records[$serviceName] = [pscustomobject]@{
                    Name = $serviceName
                    Controller = $controller
                    BeforeState = if ($null -ne $controller) { $controller.Status.ToString() } else { '' }
                    BeforeStartMode = if ($null -ne $serviceInfo) { $serviceInfo.StartMode } else { '' }
                    StartupChanged = $false
                    Error = $errorText
                }
            }

            # Отключённые службы переводим в Manual до пакетного запуска.
            if ($RequestedAction -in @('Start','Restart')) {
                foreach ($serviceName in $ServiceNames) {
                    $record = $records[$serviceName]
                    if ($record.Error) { continue }
                    if ($record.BeforeStartMode -eq 'Disabled') {
                        if (-not $EnableDisabled) {
                            $record.Error = 'Служба отключена (тип запуска Disabled).'
                            continue
                        }
                        try {
                            Set-Service -Name $serviceName -StartupType Manual -ErrorAction Stop
                            $record.StartupChanged = $true
                        }
                        catch { $record.Error = $_.Exception.Message }
                    }
                }
            }

            function Send-ServiceCommands {
                param([string[]]$Names, [ValidateSet('Start','Stop')][string]$Command)
                $sent = 0
                foreach ($name in $Names) {
                    $record = $records[$name]
                    if ($record.Error) { continue }
                    try {
                        $record.Controller.Refresh()
                        if ($Command -eq 'Start' -and
                            $record.Controller.Status -notin @('Running','StartPending')) {
                            $record.Controller.Start()
                        }
                        if ($Command -eq 'Stop' -and
                            $record.Controller.Status -notin @('Stopped','StopPending')) {
                            $record.Controller.Stop()
                        }
                    }
                    catch { $record.Error = $_.Exception.Message }
                    $sent++
                    # Небольшая пауза после каждой восьмой команды защищает SCM от всплеска.
                    if (($sent % 8) -eq 0) { Start-Sleep -Milliseconds 100 }
                }
            }

            function Wait-ServiceGroup {
                param([string[]]$Names, [string]$TargetState, [int]$TimeoutSeconds = 25)
                $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
                do {
                    $pending = @()
                    foreach ($name in $Names) {
                        $record = $records[$name]
                        if ($record.Error) { continue }
                        try {
                            $record.Controller.Refresh()
                            if ($record.Controller.Status.ToString() -ne $TargetState) { $pending += $name }
                        }
                        catch { $record.Error = $_.Exception.Message }
                    }
                    if ($pending.Count -eq 0) { return }
                    if ([DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 300 }
                } while ([DateTime]::UtcNow -lt $deadline)

                foreach ($name in $pending) {
                    $record = $records[$name]
                    if (-not $record.Error) {
                        $record.Error = "Тайм-аут: служба не перешла в состояние $TargetState за $TimeoutSeconds сек."
                    }
                }
            }

            if ($RequestedAction -eq 'Start') {
                Send-ServiceCommands -Names $ServiceNames -Command Start
                Wait-ServiceGroup -Names $ServiceNames -TargetState Running
            }
            elseif ($RequestedAction -eq 'Stop') {
                Send-ServiceCommands -Names $ServiceNames -Command Stop
                Wait-ServiceGroup -Names $ServiceNames -TargetState Stopped
            }
            else {
                Send-ServiceCommands -Names $ServiceNames -Command Stop
                Wait-ServiceGroup -Names $ServiceNames -TargetState Stopped
                $restartNames = @($ServiceNames | Where-Object { -not $records[$_].Error })
                Send-ServiceCommands -Names $restartNames -Command Start
                Wait-ServiceGroup -Names $restartNames -TargetState Running
            }

            # Одна итоговая CIM-проверка вместо отдельного запроса для каждой службы.
            $finalInfoByName = @{}
            foreach ($info in @(Get-CimInstance -ClassName Win32_Service -Filter $serviceFilter -ErrorAction Stop)) {
                if ($records.ContainsKey($info.Name)) { $finalInfoByName[$info.Name] = $info }
            }
            $targetState = if ($RequestedAction -eq 'Stop') { 'Stopped' } else { 'Running' }

            foreach ($serviceName in $ServiceNames) {
                $record = $records[$serviceName]
                $serviceInfo = $finalInfoByName[$serviceName]
                $state = if ($null -ne $serviceInfo) { $serviceInfo.State } else { '' }
                if (-not $record.Error -and $state -ne $targetState) {
                    $record.Error = "Получено состояние $state вместо $targetState."
                }
                [pscustomobject]@{
                    Name = $serviceName
                    Success = -not [bool]$record.Error
                    State = $state
                    StartMode = if ($null -ne $serviceInfo) { $serviceInfo.StartMode } else { '' }
                    ProcessId = if ($null -ne $serviceInfo) { $serviceInfo.ProcessId } else { 0 }
                    StartupChanged = $record.StartupChanged
                    BeforeState = $record.BeforeState
                    BeforeStartMode = $record.BeforeStartMode
                    Warning = ''
                    Error = $record.Error
                }
            }
        }
        foreach ($result in $results) {
            if ($result.Success) {
                $startupNote = if ($result.StartupChanged) { ' Тип запуска изменён с Disabled на Manual.' } else { '' }
                Write-Log "ГОТОВО: $($result.Name) — $actionText, состояние: $($result.State), тип запуска: $($result.StartMode).$startupNote"
                Write-Audit -Operation $Action -Target $result.Name -Before "$($result.BeforeState)/$($result.BeforeStartMode)" -After "$($result.State)/$($result.StartMode)" -Result 'Success'
            }
            else {
                Write-Log "ОШИБКА: $($result.Name) — $($result.Error)"
                Write-Audit -Operation $Action -Target $result.Name -Before "$($result.BeforeState)/$($result.BeforeStartMode)" -After '' -Result 'Failed' -ErrorText $result.Error
            }
        }
        # Обновляем только изменённые строки. Полный повторный запрос здесь не нужен.
        $localServicesByName = @{}
        foreach ($service in $script:AllServices) { $localServicesByName[$service.Name] = $service }
        foreach ($result in $results) {
            $localService = $localServicesByName[$result.Name]
            if ($null -eq $localService) { continue }
            if ($result.State) {
                $localService.State = $result.State
                $localService.Started = ($result.State -eq 'Running')
            }
            if ($result.StartMode) { $localService.StartMode = $result.StartMode }
            $localService.ProcessId = $result.ProcessId
            $localService.IsChecked = $false
        }
        Update-Grid
        $operationTimer.Stop()
        Write-Log "Пакетная операция завершена за $([Math]::Round($operationTimer.Elapsed.TotalSeconds, 1)) сек."
        Show-OperationResultWindow -ActionTitle "Команда: $actionText" -Results @($results)
    }
    catch {
        Write-Log "ОШИБКА ОПЕРАЦИИ: $($_.Exception.Message)"
        [System.Windows.MessageBox]::Show($_.Exception.Message, 'Ошибка операции', 'OK', 'Error') | Out-Null
    }
    finally {
        if ($operationTimer.IsRunning) { $operationTimer.Stop() }
        Set-Busy $false
    }
}

$ConnectButton.Add_Click({
    $computer = $ComputerBox.Text.Trim()
    if (-not $computer) {
        [System.Windows.MessageBox]::Show('Введите имя или IP компьютера.', 'Не указан компьютер', 'OK', 'Information') | Out-Null
        return
    }
    $targetPlatform = ([System.Windows.Controls.ComboBoxItem]$TargetTypeBox.SelectedItem).Content.ToString()
    Clear-ConnectionState
    $script:TargetPlatform = $targetPlatform
    $script:ConnectedComputer = $computer
    if ($script:TargetPlatform -eq 'Linux') {
        $script:UseCurrentAccount = $UseCurrentAccountCheck.IsChecked -eq $true
        try {
            $script:LinuxUser = if ($script:UseCurrentAccount) { Get-CurrentLinuxLoginName } else { $LinuxUserBox.Text.Trim() }
        }
        catch {
            Clear-ConnectionState
            [System.Windows.MessageBox]::Show($_.Exception.Message, 'Ошибка учётной записи', 'OK', 'Warning') | Out-Null
            return
        }
        $parsedPort = 0
        if (-not [int]::TryParse($LinuxPortBox.Text.Trim(), [ref]$parsedPort)) {
            Clear-ConnectionState
            [System.Windows.MessageBox]::Show('Укажите корректный числовой порт SSH.', 'Ошибка SSH', 'OK', 'Warning') | Out-Null
            return
        }
        $script:LinuxPort = $parsedPort
        $script:LinuxKeyPath = $LinuxKeyBox.Text.Trim()
        $script:Credential = $null
    }
    else {
        if ($CredentialCheck.IsChecked) {
            try { $script:Credential = Get-Credential -Message "Учётные данные для $computer" }
            catch { $script:Credential = $null }
            if ($null -eq $script:Credential) {
                Clear-ConnectionState
                Write-Log 'Подключение отменено: учётные данные не введены.'
                return
            }
        } else { $script:Credential = $null }
    }
    Write-Log "Подключение к $computer ($($script:TargetPlatform))..."
    Set-Busy $true $(if ($script:TargetPlatform -eq 'Linux') { 'Проверка SSH и systemd...' } else { 'Создание постоянной сессии...' })
    try {
        if ($script:TargetPlatform -eq 'Linux') {
            if ($null -ne $script:Session) { Remove-PSSession -Session $script:Session -ErrorAction SilentlyContinue; $script:Session=$null }
            Write-Log "Проверка TCP-порта $($script:LinuxPort)..."
            $linuxInfo = Test-LinuxConnection
            $accountMode = if ($script:UseCurrentAccount) { 'текущая УЗ Windows' } else { 'указанная SSH-УЗ' }
            Write-Log "OpenSSH: соединение проверено; строгая проверка ключа узла; без перенаправления агента и портов."
            Write-Log "Linux: $computer; пользователь: $($script:LinuxUser) ($accountMode); $linuxInfo."
        }
        else {
            Connect-RemoteSession -Computer $computer
            $account = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
            Write-Log "WinRM/WS-Man: постоянная PSSession создана; Kerberos; сервер: $computer; локальная УЗ: $account."
        }
        Load-Services -ThrowOnError
    }
    catch {
        Clear-ConnectionState
        $ConnectionStatus.Text = 'Ошибка подключения'
        $ConnectionStatus.Foreground = '#C62828'
        Write-Log "ОШИБКА ПОДКЛЮЧЕНИЯ: $($_.Exception.Message)"
        [System.Windows.MessageBox]::Show($_.Exception.Message, 'Ошибка подключения', 'OK', 'Error') | Out-Null
    }
    finally { Set-Busy $false }
})

$TargetTypeBox.Add_SelectionChanged({
    Clear-ConnectionState
    Update-TargetModeUi
})

$UseCurrentAccountCheck.Add_Checked({ Update-LinuxAccountUi })
$UseCurrentAccountCheck.Add_Unchecked({ Update-LinuxAccountUi })

$BrowseLinuxKeyButton.Add_Click({
    $dialog = New-Object Microsoft.Win32.OpenFileDialog
    $dialog.Title = 'Выберите закрытый SSH-ключ'
    $dialog.Filter = 'SSH-ключи (id_*)|id_*|Все файлы (*.*)|*.*'
    if ($dialog.ShowDialog()) { $LinuxKeyBox.Text = $dialog.FileName }
})

$RefreshButton.Add_Click({ Load-Services })
$RefreshServicesButton.Add_Click({ Load-Services })
$CollapseGroupsButton.Add_Click({ Set-AllGroupExpansion -Expanded $false })
$ExpandGroupsButton.Add_Click({ Set-AllGroupExpansion -Expanded $true })
$SearchBox.Add_TextChanged({ Update-Grid })
$StateFilter.Add_SelectionChanged({ if ($null -ne $ServicesGrid) { Update-Grid } })
$GroupFilter.Add_SelectionChanged({ if ($null -ne $ServicesGrid -and $script:AllServices.Count -gt 0) { Update-Grid } })
$groupSelectorPreviewHandler = [System.Windows.Input.MouseButtonEventHandler]{
    param($sender, $eventArgs)
    $checkBox = Find-ParentCheckBox -Element $eventArgs.OriginalSource
    if ($null -eq $checkBox -or $checkBox.Tag -ne 'GroupSelector') { return }

    $group = $checkBox.DataContext
    if ($group -is [System.Windows.Data.CollectionViewGroup]) {
        # Переключаем флажок сами и не передаём нажатие стандартному обработчику WPF.
        $newValue = -not ($checkBox.IsChecked -eq $true)
        $groupName = [string]$group.Name
        $servicesInGroup = @($script:AllServices | Where-Object Group -eq $groupName)
        foreach ($service in $servicesInGroup) { $service.IsChecked = $newValue }
        $checkBox.IsChecked = $newValue
        $ServicesGrid.Items.Refresh()
        $ServicesGrid.UpdateLayout()
        Sync-GroupSelectorStates
        Write-Log "Категория «$groupName»: $(if ($newValue) {'выбраны'} else {'сняты'}) все службы ($($servicesInGroup.Count))."
        $eventArgs.Handled = $true
    }
}
$ServicesGrid.AddHandler([System.Windows.UIElement]::PreviewMouseLeftButtonDownEvent, $groupSelectorPreviewHandler, $true)

$rowSelectorHandler = [System.Windows.RoutedEventHandler]{
    param($sender, $eventArgs)
    $checkBox = $eventArgs.Source
    if ($checkBox -is [System.Windows.Controls.CheckBox] -and $checkBox.Tag -ne 'GroupSelector') {
        [void]$ServicesGrid.Dispatcher.BeginInvoke([Action]{ Sync-GroupSelectorStates })
    }
}
$ServicesGrid.AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, $rowSelectorHandler, $true)
$SelectAllButton.Add_Click({
    foreach ($item in @($ServicesGrid.ItemsSource)) { $item.IsChecked = $true }
    $ServicesGrid.Items.Refresh()
    Sync-GroupSelectorStates
})
$ClearButton.Add_Click({
    foreach ($item in $script:AllServices) { $item.IsChecked = $false }
    $ServicesGrid.Items.Refresh()
    Sync-GroupSelectorStates
})
$StartButton.Add_Click({ Invoke-ServiceAction 'Start' })
$StopButton.Add_Click({ Invoke-ServiceAction 'Stop' })
$RestartButton.Add_Click({ Invoke-ServiceAction 'Restart' })
$SetStartupButton.Add_Click({ Set-SelectedStartupType })
$DiagnoseButton.Add_Click({ Diagnose-SelectedServices })
$RollbackButton.Add_Click({ Restore-LastSnapshot })
$MonitorProcessesButton.Add_Click({
    if (-not $script:ConnectedComputer -or
        ($script:TargetPlatform -eq 'Windows' -and ($null -eq $script:Session -or $script:Session.State -ne 'Opened'))) {
        [System.Windows.MessageBox]::Show('Сначала подключитесь к удалённому компьютеру.', 'Нет подключения', 'OK', 'Information') | Out-Null
        return
    }
    $MainTabs.SelectedIndex = 1
    if (-not $script:ProcessMonitoring) {
        $script:ProcessMonitoring = $true
        $seconds = [int]([System.Windows.Controls.ComboBoxItem]$ProcessIntervalBox.SelectedItem).Tag
        $processTimer.Interval = [TimeSpan]::FromSeconds($seconds)
        $processTimer.Start()
        $ProcessMonitorButton.Content = '■ Остановить мониторинг'
        $ProcessMonitorButton.Background = '#C62828'
        Write-Log "Открыт мониторинг процессов. Интервал: $seconds сек."
        Load-Processes
    }
})
$ProcessSearchBox.Add_TextChanged({ Update-ProcessGrid })
$ProcessRefreshButton.Add_Click({ Load-Processes })
$KillProcessButton.Add_Click({ Stop-SelectedProcesses })

$ProcessMonitorButton.Add_Click({
    if (-not $script:ConnectedComputer) {
        [System.Windows.MessageBox]::Show('Сначала подключитесь к удалённому компьютеру.', 'Нет подключения', 'OK', 'Information') | Out-Null
        return
    }

    $script:ProcessMonitoring = -not $script:ProcessMonitoring
    if ($script:ProcessMonitoring) {
        $seconds = [int]([System.Windows.Controls.ComboBoxItem]$ProcessIntervalBox.SelectedItem).Tag
        $processTimer.Interval = [TimeSpan]::FromSeconds($seconds)
        $processTimer.Start()
        $ProcessMonitorButton.Content = '■ Остановить мониторинг'
        $ProcessMonitorButton.Background = '#C62828'
        Write-Log "Мониторинг процессов включён. Интервал: $seconds сек."
        Load-Processes
    }
    else {
        $processTimer.Stop()
        $ProcessMonitorButton.Content = '▶ Мониторинг'
        $ProcessMonitorButton.Background = '#1769E0'
        Write-Log 'Мониторинг процессов остановлен.'
    }
})

$ProcessIntervalBox.Add_SelectionChanged({
    if ($null -ne $processTimer -and $null -ne $ProcessIntervalBox.SelectedItem) {
        $seconds = [int]([System.Windows.Controls.ComboBoxItem]$ProcessIntervalBox.SelectedItem).Tag
        $processTimer.Interval = [TimeSpan]::FromSeconds($seconds)
        if ($script:ProcessMonitoring) { Write-Log "Интервал мониторинга изменён: $seconds сек." }
    }
})

$processTimer.Add_Tick({ Load-Processes -Quiet })

$MainTabs.Add_SelectionChanged({
    if ($_.OriginalSource -ne $MainTabs) { return }
    if ($MainTabs.SelectedIndex -eq 1) {
        $ServicesToolbar.Visibility = 'Collapsed'
        $ServiceActionPanel.Visibility = 'Collapsed'
        if ($script:ConnectedComputer -and $script:AllProcesses.Count -eq 0) { Load-Processes }
    }
    else {
        $ServicesToolbar.Visibility = 'Visible'
        $ServiceActionPanel.Visibility = 'Visible'
    }
})

$window.Add_Closing({
    $processTimer.Stop()
    if ($null -ne $script:ActiveWinRmJob -and $script:ActiveWinRmJob.State -in @('NotStarted','Running')) {
        Stop-Job -Job $script:ActiveWinRmJob -ErrorAction SilentlyContinue
    }
    if ($null -ne $script:ActiveSshProcess -and -not $script:ActiveSshProcess.HasExited) {
        try { $script:ActiveSshProcess.Kill() } catch { }
    }
    if ($null -ne $script:Session) { Remove-PSSession -Session $script:Session -ErrorAction SilentlyContinue }
})

$ExportButton.Add_Click({
    if ($script:AllServices.Count -eq 0) { return }
    $dialog = New-Object Microsoft.Win32.SaveFileDialog
    $dialog.Filter = 'CSV (*.csv)|*.csv'
    $safeComputer = $script:ConnectedComputer -replace '[^a-zA-Z0-9._-]', '_'
    $dialog.FileName = "Services_${safeComputer}_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').csv"
    if ($dialog.ShowDialog()) {
        $script:AllServices | ForEach-Object {
            ConvertTo-SafeCsvRecord -InputObject $_ -ExcludeProperty @('IsChecked','PSComputerName','RunspaceId','PSShowComputerName')
        } |
            Export-Csv -Path $dialog.FileName -Delimiter ';' -NoTypeInformation -Encoding UTF8
        Write-Log "Экспортировано служб: $($script:AllServices.Count). Файл: $($dialog.FileName)"
    }
})

Update-TargetModeUi
Update-LinuxAccountUi
Set-Busy $false
Write-Log "Remote Service Manager $($script:AppVersion) запущен. Выберите Windows или Linux и нажмите «Подключиться»."
$window.ShowDialog() | Out-Null
