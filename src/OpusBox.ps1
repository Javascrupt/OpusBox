
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

$ErrorActionPreference = "Stop"

function Find-FirstExistingPath {
    param([string[]]$Paths)
    foreach ($p in $Paths) {
        if ($p -and (Test-Path $p)) { return $p }
    }
    return ""
}

function Sanitize-FileName {
    param([string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { return "YouTube Album" }
    foreach ($c in [System.IO.Path]::GetInvalidFileNameChars()) {
        $Name = $Name.Replace($c, '_')
    }
    $Name = $Name.Trim().TrimEnd('.')
    if ([string]::IsNullOrWhiteSpace($Name)) { return "YouTube Album" }
    return $Name
}

function Get-SettingsPath {
    $dir = Join-Path $env:APPDATA "OpusBox"
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    return (Join-Path $dir "settings.json")
}

$DefaultYtDlp = Find-FirstExistingPath @(
    "$env:USERPROFILE\.stacher\yt-dlp.exe",
    "$PSScriptRoot\yt-dlp.exe"
)

$DefaultFfmpeg = Find-FirstExistingPath @(
    "$env:USERPROFILE\.stacher\ffmpeg.exe",
    "$PSScriptRoot\ffmpeg.exe"
)

$DefaultPicard = Find-FirstExistingPath @(
$DefaultCookies = Join-Path $env:APPDATA "OpusBox\youtube-cookies.txt"
    "$env:ProgramFiles\MusicBrainz Picard\picard.exe",
    "${env:ProgramFiles(x86)}\MusicBrainz Picard\picard.exe",
    "$env:LOCALAPPDATA\Programs\MusicBrainz Picard\picard.exe"
)

$DefaultOutput = "$env:USERPROFILE\Desktop\Music"

[xml]$xaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="OpusBox v0.3.18"
    Width="900"
    Height="720"
    MinWidth="760"
    MinHeight="620"
    WindowStartupLocation="CenterScreen"
    Background="#0B0D12"
    Foreground="#F5F7FB"
    FontFamily="Segoe UI"
    ResizeMode="CanResize">
    <Window.Resources>
        <SolidColorBrush x:Key="Bg" Color="#0B0D12"/>
        <SolidColorBrush x:Key="Panel" Color="#12151C"/>
        <SolidColorBrush x:Key="Panel2" Color="#181C25"/>
        <SolidColorBrush x:Key="Border" Color="#272C38"/>
        <SolidColorBrush x:Key="Muted" Color="#8F98A8"/>
        <SolidColorBrush x:Key="Text" Color="#F5F7FB"/>
        <SolidColorBrush x:Key="Accent" Color="#8B5CF6"/>
        <SolidColorBrush x:Key="AccentHover" Color="#9F75FF"/>
        <SolidColorBrush x:Key="Good" Color="#37D67A"/>
        <SolidColorBrush x:Key="Warn" Color="#F5B942"/>

        <Style TargetType="TextBox">
            <Setter Property="Foreground" Value="{StaticResource Text}"/>
            <Setter Property="Background" Value="#0F1218"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,9"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="CaretBrush" Value="White"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>

        <Style x:Key="PrimaryButton" TargetType="Button">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Background" Value="{StaticResource Accent}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="18,10"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" CornerRadius="9" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="{StaticResource AccentHover}"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Bd" Property="Opacity" Value="0.45"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="SecondaryButton" TargetType="Button">
            <Setter Property="Foreground" Value="{StaticResource Text}"/>
            <Setter Property="Background" Value="#1A1F29"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="14,9"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#242A36"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{StaticResource Text}"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>

        <Style TargetType="ProgressBar">
            <Setter Property="Height" Value="8"/>
            <Setter Property="Foreground" Value="{StaticResource Accent}"/>
            <Setter Property="Background" Value="#252A35"/>
            <Setter Property="BorderThickness" Value="0"/>
        </Style>

        <!-- Slim dark scrollbar for the Status / Advanced / Log panel -->
        <Style x:Key="ModernThumbStyle" TargetType="Thumb">
            <Setter Property="Background" Value="#4A5160"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Thumb">
                        <Border x:Name="ThumbBorder"
                                Background="{TemplateBinding Background}"
                                CornerRadius="4"
                                Margin="2,0"/>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="ThumbBorder" Property="Background" Value="#697386"/>
                            </Trigger>
                            <Trigger Property="IsDragging" Value="True">
                                <Setter TargetName="ThumbBorder" Property="Background" Value="{StaticResource Accent}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="ModernScrollBarStyle" TargetType="ScrollBar">
            <Setter Property="Width" Value="10"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Grid Background="Transparent" Width="{TemplateBinding Width}">
                            <Track x:Name="PART_Track"
                                   IsDirectionReversed="True"
                                   Focusable="False">
                                <Track.DecreaseRepeatButton>
                                    <RepeatButton Command="ScrollBar.PageUpCommand"
                                                  Opacity="0"
                                                  Focusable="False"/>
                                </Track.DecreaseRepeatButton>
                                <Track.Thumb>
                                    <Thumb Style="{StaticResource ModernThumbStyle}"/>
                                </Track.Thumb>
                                <Track.IncreaseRepeatButton>
                                    <RepeatButton Command="ScrollBar.PageDownCommand"
                                                  Opacity="0"
                                                  Focusable="False"/>
                                </Track.IncreaseRepeatButton>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="{x:Type ScrollBar}" BasedOn="{StaticResource ModernScrollBarStyle}"/>
    </Window.Resources>

    <Grid Margin="26">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Grid Grid.Row="0" Margin="0,0,0,22">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>

            <Border Width="48" Height="48" CornerRadius="14" Background="#8B5CF6">
                <TextBlock Text="♫" FontSize="25" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="White"/>
            </Border>

            <StackPanel Grid.Column="1" Margin="14,0,0,0" VerticalAlignment="Center">
                <TextBlock Text="OpusBox" FontSize="25" FontWeight="SemiBold"/>
                <TextBlock Text="YouTube → Opus → MusicBrainz   •   v0.3.18" Foreground="{StaticResource Muted}" FontSize="13" Margin="0,3,0,0"/>
            </StackPanel>

            <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                <Border CornerRadius="14"
                        Background="#151922"
                        BorderBrush="{StaticResource Border}"
                        BorderThickness="1"
                        Padding="11,7">
                    <StackPanel Orientation="Horizontal">
                        <Ellipse x:Name="HealthDot" Width="8" Height="8" Fill="{StaticResource Good}" Margin="0,0,7,0"/>
                        <TextBlock x:Name="HealthText" Text="Tools ready" FontSize="12" Foreground="#CAD0DA"/>
                    </StackPanel>
                </Border>
            </StackPanel>
        </Grid>

        <!-- URL -->
        <Border Grid.Row="1" Background="{StaticResource Panel}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="14" Padding="18" Margin="0,0,0,16">
            <StackPanel>
                <TextBlock Text="YouTube album or playlist" FontWeight="SemiBold" FontSize="14" Margin="0,0,0,8"/>
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="12"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="10"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox x:Name="UrlBox"
                             Grid.Column="0"
                             Height="42"
                             ToolTip="Paste a YouTube album or playlist URL"/>
                    <Button x:Name="PreviewButton"
                            Grid.Column="2"
                            Style="{StaticResource SecondaryButton}"
                            Content="Load album"
                            MinWidth="108"
                            Height="42"/>
                    <Button x:Name="TagLibraryUrlButton"
                            Grid.Column="4"
                            Style="{StaticResource PrimaryButton}"
                            Content="Tag Existing Music"
                            MinWidth="160"
                            Height="42"/>
                </Grid>
            </StackPanel>
        </Border>

        <!-- Album preview -->
        <Border x:Name="PreviewCard" Grid.Row="2" Background="{StaticResource Panel}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="14" Padding="18" Margin="0,0,0,16">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="104"/>
                    <ColumnDefinition Width="18"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <Border Width="104" Height="104" CornerRadius="11" Background="#1B202A" ClipToBounds="True">
                    <Grid>
                        <TextBlock x:Name="CoverPlaceholder" Text="♫" FontSize="38" Foreground="#697386" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        <Image x:Name="CoverImage" Stretch="UniformToFill"/>
                    </Grid>
                </Border>

                <StackPanel Grid.Column="2" VerticalAlignment="Center">
                    <TextBlock x:Name="AlbumTitleText" Text="No album loaded" FontSize="20" FontWeight="SemiBold" TextTrimming="CharacterEllipsis"/>
                    <TextBlock x:Name="AlbumMetaText" Text="Paste a link above and load the album." Foreground="{StaticResource Muted}" FontSize="13" Margin="0,7,0,0"/>
                    <StackPanel Orientation="Horizontal" Margin="0,12,0,0">
                        <Border Background="#1D2330" CornerRadius="7" Padding="9,5" Margin="0,0,8,0">
                            <TextBlock x:Name="TrackCountBadge" Text="— tracks" Foreground="#C8D0DC" FontSize="12"/>
                        </Border>
                        <Border Background="#1D2330" CornerRadius="7" Padding="9,5">
                            <TextBlock Text="OPUS" Foreground="#C8D0DC" FontSize="12" FontWeight="SemiBold"/>
                        </Border>
                    </StackPanel>
                </StackPanel>

                <Button x:Name="DownloadButton"
                        Grid.Column="3"
                        Style="{StaticResource PrimaryButton}"
                        Content="Download &amp; Tag"
                        MinWidth="170"
                        Height="44"
                        VerticalAlignment="Center"/>
            </Grid>
        </Border>

        <!-- Main content -->
        <Grid Grid.Row="3">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="1.55*"/>
                <ColumnDefinition Width="16"/>
                <ColumnDefinition Width="1*"/>
            </Grid.ColumnDefinitions>

            <Border Grid.Column="0" Background="{StaticResource Panel}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="14" Padding="18">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <Grid Grid.Row="0" Margin="0,0,0,13">
                        <TextBlock Text="Tracks" FontSize="15" FontWeight="SemiBold"/>
                        <TextBlock x:Name="TrackStatusText" Text="Waiting" HorizontalAlignment="Right" Foreground="{StaticResource Muted}" FontSize="12"/>
                    </Grid>

                    <ProgressBar x:Name="OverallProgress" Grid.Row="1" Minimum="0" Maximum="100" Value="0" Margin="0,0,0,14"/>

                    <ListBox x:Name="TrackList" Grid.Row="2" Background="Transparent" BorderThickness="0" Foreground="{StaticResource Text}" ScrollViewer.HorizontalScrollBarVisibility="Disabled">
                        <ListBox.ItemTemplate>
                            <DataTemplate>
                                <Grid Margin="0,4">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="30"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <Border Width="23" Height="23" CornerRadius="7" Background="#1D2330" VerticalAlignment="Center">
                                        <TextBlock Text="{Binding Index}" HorizontalAlignment="Center" VerticalAlignment="Center" FontSize="11" Foreground="#AAB3C2"/>
                                    </Border>
                                    <TextBlock Grid.Column="1" Text="{Binding Title}" Margin="9,0,0,0" VerticalAlignment="Center" TextTrimming="CharacterEllipsis" FontSize="13"/>
                                </Grid>
                            </DataTemplate>
                        </ListBox.ItemTemplate>
                    </ListBox>
                </Grid>
            </Border>

            <Border Grid.Column="2" Background="{StaticResource Panel}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="14" Padding="18">
                <ScrollViewer VerticalScrollBarVisibility="Auto"
                              HorizontalScrollBarVisibility="Disabled"
                              CanContentScroll="False"
                              Padding="0,0,4,0">
                    <StackPanel>
                    <TextBlock Text="Status" FontSize="15" FontWeight="SemiBold" Margin="0,0,0,15"/>

                    <Border Background="#171B24" CornerRadius="10" Padding="13" Margin="0,0,0,12">
                        <StackPanel>
                            <TextBlock x:Name="StatusTitle" Text="Ready when you are" FontWeight="SemiBold" FontSize="13"/>
                            <TextBlock x:Name="StatusDetail" Text="Load an album to get started." Foreground="{StaticResource Muted}" FontSize="12" Margin="0,5,0,0" TextWrapping="Wrap"/>
                        </StackPanel>
                    </Border>

                    <TextBlock Text="Save location" Foreground="{StaticResource Muted}" FontSize="11" Margin="0,4,0,5"/>
                    <TextBlock x:Name="SaveLocationText" Text="" FontSize="12" TextWrapping="Wrap" Margin="0,0,0,15"/>

                    <Expander x:Name="AdvancedExpander" Header="Advanced settings" Foreground="{StaticResource Text}" Margin="0,0,0,10">
                        <StackPanel Margin="0,12,0,0">
                            <TextBlock Text="Music folder" Foreground="{StaticResource Muted}" FontSize="11" Margin="0,0,0,4"/>
                            <Grid Margin="0,0,0,10">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="*"/>
                                    <ColumnDefinition Width="8"/>
                                    <ColumnDefinition Width="Auto"/>
                                </Grid.ColumnDefinitions>
                                <TextBox x:Name="OutputBox" Height="36" Grid.Column="0" FontSize="12" Padding="9,6"/>
                                <Button x:Name="BrowseOutputButton" Grid.Column="2" Style="{StaticResource SecondaryButton}" Content="Browse" Padding="10,7"/>
                            </Grid>

                            <TextBlock Text="yt-dlp.exe" Foreground="{StaticResource Muted}" FontSize="11" Margin="0,0,0,4"/>
                            <TextBox x:Name="YtDlpBox" Height="34" FontSize="11" Padding="8,5" Margin="0,0,0,9"/>

                            <TextBlock Text="Picard.exe" Foreground="{StaticResource Muted}" FontSize="11" Margin="0,0,0,4"/>
                            <TextBox x:Name="PicardBox" Height="34" FontSize="11" Padding="8,5" Margin="0,0,0,10"/>

                            <TextBlock Text="YouTube authentication" Foreground="{StaticResource Muted}" FontSize="11" Margin="0,0,0,4"/>
                            <Border Background="#0F1218" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="8" Padding="10" Margin="0,0,0,10">
                                <StackPanel>
                                    <Grid>
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="8"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <StackPanel Grid.Column="0">
                                            <TextBlock x:Name="YouTubeAuthStatusText" Text="Not connected" FontWeight="SemiBold" FontSize="12"/>
                                            <TextBlock x:Name="YouTubeAuthDetailText" Text="Connect once using your browser login. Chrome is tried automatically."
                                                       Foreground="{StaticResource Muted}" FontSize="10" TextWrapping="Wrap" Margin="0,2,0,0"/>
                                        </StackPanel>
                                        <Button x:Name="ConnectYouTubeButton" Grid.Column="2" Style="{StaticResource SecondaryButton}" Content="Connect YouTube" Padding="11,7"/>
                                    </Grid>
                                    <Button x:Name="BrowseCookiesButton" Style="{StaticResource SecondaryButton}" Content="Use existing cookies file..." Padding="9,5"
                                            HorizontalAlignment="Left" FontSize="10" Margin="0,9,0,0"/>
                                    <TextBox x:Name="CookiesBox" Visibility="Collapsed"/>
                                </StackPanel>
                            </Border>

                            <TextBlock Text="After downloading, OpusBox asks whether to tag the new files with Picard." Foreground="{StaticResource Muted}" FontSize="11" TextWrapping="Wrap" Margin="0,0,0,10"/>
                            <CheckBox x:Name="OpenFolderCheck" Content="Open album folder when finished" IsChecked="True"/>
                        </StackPanel>
                    </Expander>

                    <Expander x:Name="LogExpander" Header="View log" Foreground="{StaticResource Text}">
                        <TextBox x:Name="LogBox" Margin="0,10,0,0" Height="145" IsReadOnly="True" AcceptsReturn="True" TextWrapping="NoWrap" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="10" Background="#0D1016"/>
                    </Expander>
                    </StackPanel>
                </ScrollViewer>
            </Border>
        </Grid>

        <Grid Grid.Row="4" Margin="0,17,0,0">
            <TextBlock Text="OpusBox keeps the audio as Opus. Picard only updates tags and artwork." Foreground="{StaticResource Muted}" FontSize="11"/>
            <TextBlock x:Name="FooterState" Text="Idle" HorizontalAlignment="Right" Foreground="{StaticResource Muted}" FontSize="11"/>
        </Grid>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$Window = [Windows.Markup.XamlReader]::Load($reader)

$names = @(
    "HealthDot","HealthText","TagLibraryUrlButton","UrlBox","PreviewButton","PreviewCard","CoverImage","CoverPlaceholder",
    "AlbumTitleText","AlbumMetaText","TrackCountBadge","DownloadButton","TrackStatusText",
    "OverallProgress","TrackList","StatusTitle","StatusDetail","SaveLocationText",
    "AdvancedExpander","OutputBox","BrowseOutputButton","YtDlpBox","PicardBox","CookiesBox","BrowseCookiesButton","ConnectYouTubeButton","YouTubeAuthStatusText","YouTubeAuthDetailText",
    "OpenFolderCheck","LogExpander","LogBox","FooterState"
)
foreach ($n in $names) { Set-Variable -Name $n -Value $Window.FindName($n) -Scope Script }

$script:CurrentProcess = $null
$script:StdoutTask = $null
$script:StderrTask = $null
$script:JobMode = ""
$script:JobOutput = New-Object System.Collections.Generic.List[string]
$script:PendingDownload = $false
$script:PendingPreviewAfterResolve = $false
$script:OriginalMusicUrl = ""
$script:AlbumTitle = ""
$script:AlbumFolder = ""
$script:ResolvedUrl = ""
$script:AlbumThumb = ""
$script:TrackCount = 0
$script:LargePlaylistCutoff = 50

$script:DownloadedThisRun = 0
$script:SkippedThisRun = 0
$script:FailedThisRun = New-Object System.Collections.Generic.List[object]
$script:FailedReportPath = ""
$script:ArchiveFile = ""
$script:TrackManifestPath = ""
$script:DownloadMapLog = ""
$script:PresentVideoIds = @{}

$script:DownloadArgs = @()
$script:LastArchiveCount = 0
$script:LastProgressTime = Get-Date
$script:WatchdogRestartPending = $false
$script:WatchdogHardStop = $false
$script:WatchdogRestarts = 0
$script:WatchdogMaxRestarts = 12
$script:WatchdogStallSeconds = 180
$script:WatchdogStartupGraceSeconds = 600
$script:WatchdogLastStallTrack = 0
$script:WatchdogSameTrackStalls = 0
$script:WatchdogPlaylistStart = 0
$script:CookieImportTemp = ""
$script:CookieImportFinal = ""
$script:CookieImportBrowser = ""
$script:CookieValidationPath = ""
$script:RecoveryPassActive = $false
$script:RecoveryIndices = @()
$script:RecoveryInitialCount = 0
$script:PrimaryDownloadArgs = @()

$script:NewFilesBeforeRun = @{}
$script:ExistingIndicesBeforeRun = @{}
$script:TagCandidates = @()
$script:TagBatchSize = 25
$script:TagWaitSeconds = 45
$script:AutoPicardProcess = $null
$script:AutoPicardLogPath = ""
$script:AutoPicardLogCache = ""
$script:AutoPicardNewFiles = 0
$script:AutoPicardBatchCount = 0

$script:CurrentTrack = 0
$script:Tracks = @()

function Write-Log {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return }
    $stamp = Get-Date -Format "HH:mm:ss"
    $LogBox.AppendText("[$stamp] $Text`r`n")
    $LogBox.ScrollToEnd()
}

function Set-Status {
    param(
        [string]$Title,
        [string]$Detail,
        [string]$Footer = $null
    )
    $StatusTitle.Text = $Title
    $StatusDetail.Text = $Detail
    if ($Footer) { $FooterState.Text = $Footer }
}

function Set-Busy {
    param([bool]$Busy)
    $PreviewButton.IsEnabled = -not $Busy
    $DownloadButton.IsEnabled = -not $Busy
    $UrlBox.IsEnabled = -not $Busy
}

function Update-ToolHealth {
    $ytOk = Test-Path $YtDlpBox.Text
    $picardOk = Test-Path $PicardBox.Text
    if ($ytOk -and $picardOk) {
        $HealthDot.Fill = [Windows.Media.Brushes]::LightGreen
        $HealthText.Text = "Tools ready"
    } elseif ($ytOk) {
        $HealthDot.Fill = [Windows.Media.Brushes]::Goldenrod
        $HealthText.Text = "Picard not found"
    } else {
        $HealthDot.Fill = [Windows.Media.Brushes]::IndianRed
        $HealthText.Text = "yt-dlp not found"
    }
}

function Load-Settings {
    $OutputBox.Text = $DefaultOutput
    $YtDlpBox.Text = $DefaultYtDlp
    $PicardBox.Text = $DefaultPicard
    $CookiesBox.Text = if (Test-Path $DefaultCookies) { $DefaultCookies } else { "" }

    $path = Get-SettingsPath
    if (Test-Path $path) {
        try {
            $s = Get-Content $path -Raw | ConvertFrom-Json
            if ($s.output) { $OutputBox.Text = $s.output }
            if ($s.ytdlp) { $YtDlpBox.Text = $s.ytdlp }
            if ($s.picard) { $PicardBox.Text = $s.picard }
            if ($s.cookies) { $CookiesBox.Text = $s.cookies }
            if ($null -ne $s.openfolder) { $OpenFolderCheck.IsChecked = [bool]$s.openfolder }
        } catch {}
    }
    $SaveLocationText.Text = $OutputBox.Text
    Update-ToolHealth
    Update-YouTubeAuthStatus
}

function Save-Settings {
    try {
        $obj = [ordered]@{
            output = $OutputBox.Text
            ytdlp = $YtDlpBox.Text
            picard = $PicardBox.Text
            cookies = $CookiesBox.Text
            openfolder = [bool]$OpenFolderCheck.IsChecked
        }
        $obj | ConvertTo-Json | Set-Content (Get-SettingsPath) -Encoding UTF8
    } catch {}
}

function Set-Cover {
    param([string]$Url)
    $CoverImage.Source = $null
    $CoverPlaceholder.Visibility = "Visible"
    if ([string]::IsNullOrWhiteSpace($Url)) { return }
    try {
        $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
        $bmp.BeginInit()
        $bmp.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bmp.UriSource = New-Object System.Uri($Url)
        $bmp.EndInit()
        $CoverImage.Source = $bmp
        $CoverPlaceholder.Visibility = "Collapsed"
    } catch {
        Write-Log "Could not load album artwork preview."
    }
}

function Convert-ToProcessArgumentString {
    param([string[]]$Arguments)

    $quoted = foreach ($arg in $Arguments) {
        if ($null -eq $arg) { $arg = "" }

        $a = [string]$arg
        $a = $a -replace '(\\*)"', '$1$1\"'
        $a = $a -replace '(\\+)$', '$1$1'
        '"' + $a + '"'
    }
    return ($quoted -join ' ')
}

function Get-YtDlpAuthArgs {
    $cookiePath = $CookiesBox.Text.Trim()
    if (-not [string]::IsNullOrWhiteSpace($cookiePath)) {
        if (Test-Path -LiteralPath $cookiePath) {
            return @("--cookies", $cookiePath)
        }
        Write-Log "WARNING: cookies.txt path is set but the file does not exist: $cookiePath"
    }
    return @()
}

function Update-YouTubeAuthStatus {
    $cookiePath = $CookiesBox.Text.Trim()
    if (-not [string]::IsNullOrWhiteSpace($cookiePath) -and (Test-Path -LiteralPath $cookiePath)) {
        $YouTubeAuthStatusText.Text = "Saved session"
        $YouTubeAuthStatusText.Foreground = [Windows.Media.Brushes]::Goldenrod
        $YouTubeAuthDetailText.Text = "A saved session exists. Click Verify to confirm YouTube still accepts it."
        $ConnectYouTubeButton.Content = "Verify"
    } else {
        $YouTubeAuthStatusText.Text = "Not connected"
        $YouTubeAuthStatusText.Foreground = [Windows.Media.Brushes]::Goldenrod
        $YouTubeAuthDetailText.Text = "Connect once using your browser login. Chrome is tried automatically."
        $ConnectYouTubeButton.Content = "Connect YouTube"
    }
}

function Start-YouTubeCookieValidation {
    param([string]$CookiePath)

    if ([string]::IsNullOrWhiteSpace($CookiePath) -or -not (Test-Path -LiteralPath $CookiePath)) {
        throw "The imported YouTube session file could not be found."
    }

    $script:CookieValidationPath = $CookiePath
    $ConnectYouTubeButton.IsEnabled = $false
    $ConnectYouTubeButton.Content = "Verifying..."
    $YouTubeAuthStatusText.Text = "Verifying..."
    $YouTubeAuthStatusText.Foreground = [Windows.Media.Brushes]::Goldenrod
    $YouTubeAuthDetailText.Text = "Checking that YouTube accepts this saved session for an actual video."
    Write-Log "YouTube authentication: validating saved session against a real video."

    $args = @(
        "--cookies", $CookiePath,
        "--skip-download",
        "--playlist-items", "1",
        "https://www.youtube.com/playlist?list=PLaV7QvpXOvtA"
    )
    Start-BackgroundCommand -Mode "cookievalidate" -Exe $YtDlpBox.Text -CommandArgs $args
}

function Start-FirefoxCookieFallback {
    $appDir = Split-Path $DefaultCookies -Parent
    New-Item -ItemType Directory -Path $appDir -Force | Out-Null
    $script:CookieImportFinal = $DefaultCookies
    $script:CookieImportTemp = Join-Path $appDir ("youtube-cookies-import-{0}.txt" -f ([guid]::NewGuid().ToString("N")))
    $script:CookieImportBrowser = "firefox"

    $ConnectYouTubeButton.IsEnabled = $false
    $ConnectYouTubeButton.Content = "Trying Firefox..."
    $YouTubeAuthStatusText.Text = "Trying Firefox..."
    $YouTubeAuthStatusText.Foreground = [Windows.Media.Brushes]::Goldenrod
    $YouTubeAuthDetailText.Text = "Chrome blocked cookie decryption. OpusBox is trying Firefox automatically."
    Write-Log "YouTube authentication: Chrome DPAPI decryption failed; trying Firefox."

    $args = @(
        "--cookies-from-browser", "firefox",
        "--cookies", $script:CookieImportTemp,
        "--skip-download",
        "https://www.youtube.com/"
    )
    Start-BackgroundCommand -Mode "cookieimport" -Exe $YtDlpBox.Text -CommandArgs $args
}

function Start-YouTubeConnection {
    if (-not (Test-Path -LiteralPath $YtDlpBox.Text)) {
        $AdvancedExpander.IsExpanded = $true
        [System.Windows.MessageBox]::Show("OpusBox can't find yt-dlp.exe. Set the yt-dlp path first.", "OpusBox") | Out-Null
        return
    }

    if (@(Get-Process chrome -ErrorAction SilentlyContinue).Count -gt 0) {
        $answer = [System.Windows.MessageBox]::Show(
            "Chrome needs to be fully closed for a few seconds so OpusBox can copy your YouTube login.`r`n`r`nClose every Chrome window, then click OK. OpusBox will not close Chrome for you.",
            "Connect YouTube",
            [System.Windows.MessageBoxButton]::OKCancel,
            [System.Windows.MessageBoxImage]::Information
        )
        if ($answer -ne [System.Windows.MessageBoxResult]::OK) { return }
        Start-Sleep -Milliseconds 300
        if (@(Get-Process chrome -ErrorAction SilentlyContinue).Count -gt 0) {
            [System.Windows.MessageBox]::Show(
                "Chrome is still running. Close it completely, including background Chrome processes, then click Connect YouTube again.",
                "Chrome is still open"
            ) | Out-Null
            return
        }
    }

    $appDir = Split-Path $DefaultCookies -Parent
    New-Item -ItemType Directory -Path $appDir -Force | Out-Null
    $script:CookieImportFinal = $DefaultCookies
    $script:CookieImportTemp = Join-Path $appDir ("youtube-cookies-import-{0}.txt" -f ([guid]::NewGuid().ToString("N")))
    try { Remove-Item -LiteralPath $script:CookieImportTemp -Force -ErrorAction SilentlyContinue } catch {}

    $ConnectYouTubeButton.IsEnabled = $false
    $ConnectYouTubeButton.Content = "Connecting..."
    $YouTubeAuthStatusText.Text = "Connecting..."
    $YouTubeAuthStatusText.Foreground = [Windows.Media.Brushes]::Goldenrod
    $YouTubeAuthDetailText.Text = "Reading your Chrome YouTube session. This usually takes a few seconds."
    Write-Log "YouTube authentication: importing session from Chrome."

    $script:CookieImportBrowser = "chrome"
    $args = @(
        "--cookies-from-browser", "chrome",
        "--cookies", $script:CookieImportTemp,
        "--skip-download",
        "https://www.youtube.com/"
    )
    Start-BackgroundCommand -Mode "cookieimport" -Exe $YtDlpBox.Text -CommandArgs $args
}

function Start-BackgroundCommand {
    param(
        [string]$Mode,
        [string]$Exe,
        [string[]]$CommandArgs
    )

    if ($script:CurrentProcess) {
        try {
            if (-not $script:CurrentProcess.HasExited) { $script:CurrentProcess.Kill() }
            $script:CurrentProcess.Dispose()
        } catch {}
    }

    $script:JobMode = $Mode

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Exe
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.Arguments = Convert-ToProcessArgumentString $CommandArgs

    $urlArg = $CommandArgs | Where-Object { $_ -match '^https?://' } | Select-Object -Last 1
    Write-Log ("Launching {0}; URL: {1}" -f $Mode, $urlArg)

    $script:CurrentProcess = New-Object System.Diagnostics.Process
    $script:CurrentProcess.StartInfo = $psi

    [void]$script:CurrentProcess.Start()

    $script:StdoutTask = $script:CurrentProcess.StandardOutput.ReadToEndAsync()
    $script:StderrTask = $script:CurrentProcess.StandardError.ReadToEndAsync()
}

function Start-MusicUrlResolve {
    param([string]$MusicUrl)

    $script:OriginalMusicUrl = $MusicUrl
    $script:PendingPreviewAfterResolve = $true

    Set-Busy $true
    $OverallProgress.IsIndeterminate = $true
    $TrackList.ItemsSource = $null
    $AlbumTitleText.Text = "Resolving YouTube Music link…"
    $AlbumMetaText.Text = "Letting yt-dlp return the regular YouTube playlist URL"
    $TrackCountBadge.Text = "— tracks"
    Set-Status "Resolving link" "YouTube Music detected. Getting yt-dlp's redirected YouTube URL first." "Resolving"
    Write-Log "YouTube Music link detected."
    Write-Log "Running yt-dlp once to capture its redirected URL."

    $resolveArgs = @(
        "--flat-playlist",
        "--playlist-items", "1",
        "--print", "%(playlist_title)s"
    )
    $resolveArgs += @(Get-YtDlpAuthArgs)
    $resolveArgs += $MusicUrl

    Start-BackgroundCommand -Mode "resolve" -Exe $YtDlpBox.Text -CommandArgs $resolveArgs
}

function Start-Preview {
    if (-not (Test-Path $YtDlpBox.Text)) {
        $AdvancedExpander.IsExpanded = $true
        [System.Windows.MessageBox]::Show("I can't find yt-dlp.exe. Set the path under Advanced settings.", "OpusBox")
        return
    }

    $url = $UrlBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($url)) {
        [System.Windows.MessageBox]::Show("Paste a YouTube album or playlist URL first.", "OpusBox")
        return
    }

    if ($url -match '(^|//)music\.youtube\.com') {
        Start-MusicUrlResolve $url
        return
    }

    $script:ResolvedUrl = $url

    Set-Busy $true
    $OverallProgress.IsIndeterminate = $true
    $TrackList.ItemsSource = $null
    $AlbumTitleText.Text = "Reading album…"
    $AlbumMetaText.Text = "Asking yt-dlp for playlist information"
    $TrackCountBadge.Text = "— tracks"
    Set-Status "Loading album" "Reading the playlist before downloading anything." "Reading metadata"
    Write-Log "Loading playlist information."

    $previewArgs = @(
        "--flat-playlist",
        "--dump-single-json",
        "--no-warnings"
    )
    $previewArgs += @(Get-YtDlpAuthArgs)
    $previewArgs += $script:ResolvedUrl
    Start-BackgroundCommand -Mode "preview" -Exe $YtDlpBox.Text -CommandArgs $previewArgs
}

function Start-Download {
    if (-not $script:AlbumTitle) {
        $script:PendingDownload = $true
        Start-Preview
        return
    }

    if ([string]::IsNullOrWhiteSpace($script:ResolvedUrl)) {
        $script:ResolvedUrl = $UrlBox.Text.Trim()
    }

    $root = $OutputBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($root)) { $root = $DefaultOutput }
    if (-not (Test-Path $root)) { New-Item -ItemType Directory -Path $root -Force | Out-Null }

    $safeAlbum = Sanitize-FileName $script:AlbumTitle
    $script:AlbumFolder = Join-Path $root $safeAlbum
    New-Item -ItemType Directory -Path $script:AlbumFolder -Force | Out-Null

    $script:NewFilesBeforeRun = @{}
    Get-ChildItem -Path $script:AlbumFolder -Filter "*.opus" -File -ErrorAction SilentlyContinue | ForEach-Object {
        $script:NewFilesBeforeRun[$_.FullName.ToLowerInvariant()] = $true
    }

    $script:ExistingIndicesBeforeRun = Get-LocalPlaylistIndexSet

    $script:DownloadedThisRun = 0
    $script:SkippedThisRun = 0
    $script:FailedThisRun = New-Object System.Collections.Generic.List[object]
    $script:FailedReportPath = Join-Path $script:AlbumFolder "OpusBox-Failed-Tracks.txt"
    $script:WatchdogRestarts = 0
    $script:WatchdogRestartPending = $false
    $script:WatchdogHardStop = $false
    $script:WatchdogLastStallTrack = 0
    $script:WatchdogSameTrackStalls = 0
    $script:WatchdogPlaylistStart = 0
    $script:RecoveryPassActive = $false
    $script:RecoveryIndices = @()
    $script:RecoveryInitialCount = 0
    $script:PrimaryDownloadArgs = @()
    $script:LastArchiveCount = 0
    $script:LastProgressTime = Get-Date

    $SaveLocationText.Text = $script:AlbumFolder
    $script:CurrentTrack = 0
    $OverallProgress.IsIndeterminate = $false
    $OverallProgress.Value = 0
    $TrackStatusText.Text = "0 of $($script:TrackCount) complete"
    Set-Busy $true
    Set-Status "Downloading" "Downloading with resume protection, retry limits, and a 20-second network timeout." "Downloading"
    $TrackStatusText.Text = "Starting…"
    Write-Log "Output folder: $script:AlbumFolder"

    $archiveFile = Join-Path $script:AlbumFolder ".opusbox-download-archive.txt"
    $script:ArchiveFile = $archiveFile
    $script:TrackManifestPath = Join-Path $script:AlbumFolder ".opusbox-track-map.json"
    $script:DownloadMapLog = Join-Path $script:AlbumFolder ".opusbox-download-map.tsv"

    # Build/migrate video-ID identity before yt-dlp starts. This lets OpusBox
    # synchronize old recovery downloads back into yt-dlp's archive and prevents
    # playlist-index shifts from creating duplicate songs.
    [void](Refresh-TrackManifestFromDisk)
    Sync-DownloadArchiveFromManifest
    Write-DuplicateTrackReport

    # This is a per-run append log emitted by yt-dlp after the final audio file is moved.
    try { Remove-Item -LiteralPath $script:DownloadMapLog -Force -ErrorAction SilentlyContinue } catch {}

    $downloadArgs = @(
        "--yes-playlist",
        "--ignore-errors",
        "--newline",

        "--download-archive", $archiveFile,
        "--retries", "3",
        "--fragment-retries", "3",
        "--socket-timeout", "20",

        "--extract-audio",
        "--audio-format", "opus",
        "--embed-metadata",
        "--embed-thumbnail",
        "--convert-thumbnails", "jpg",
        "--output", (Join-Path $script:AlbumFolder "%(playlist_index)02d - %(title)s.%(ext)s"),
        "--print-to-file", "after_move:%(id)s`t%(playlist_index)s`t%(filepath)s", $script:DownloadMapLog
    )

    if ($DefaultFfmpeg -and (Test-Path $DefaultFfmpeg)) {
        $downloadArgs += @("--ffmpeg-location", (Split-Path $DefaultFfmpeg -Parent))
    }

    $authArgs = @(Get-YtDlpAuthArgs)
    if ($authArgs.Count -gt 0) {
        $downloadArgs += $authArgs
        Write-Log "YouTube authentication: using configured cookies.txt file."
    } else {
        Write-Log "YouTube authentication: no cookies.txt configured."
    }

    Write-Log "Downloading from: $script:ResolvedUrl"
    Write-Log "Resume archive: $archiveFile"
    Write-Log "Retry policy: 3 retries / 3 fragment retries / 20s socket timeout; repeated stalled items are skipped after two watchdog hits."
    Write-Log "Previously completed items in the archive will be skipped automatically."
    $downloadArgs += $script:ResolvedUrl
    $script:DownloadArgs = @($downloadArgs)
    $script:PrimaryDownloadArgs = @($downloadArgs)
    $script:LastArchiveCount = Get-ArchiveCompletedCount
    $script:LastProgressTime = Get-Date
    Start-BackgroundCommand -Mode "download" -Exe $YtDlpBox.Text -CommandArgs $script:DownloadArgs
}

function Start-Picard {
    if ($script:TrackCount -gt $script:LargePlaylistCutoff) {
        $OverallProgress.IsIndeterminate = $false
        $OverallProgress.Value = 100
        $TrackStatusText.Text = "Download complete"
        Set-Status "Large playlist downloaded" "Picard album matching was skipped for $($script:TrackCount) tracks. Use Tag Existing Music to fingerprint-tag them in batches." "Ready to batch tag"
        Write-Log "Large playlist detected ($($script:TrackCount) tracks). Skipping album clustering in Picard."
        Write-Log "Use Tag Existing Music for batched AcoustID scanning."
        Set-Busy $false

        if ([bool]$OpenFolderCheck.IsChecked -and (Test-Path $script:AlbumFolder)) {
            Start-Process explorer.exe -ArgumentList @($script:AlbumFolder)
        }
        return
    }

    if (-not (Test-Path $PicardBox.Text)) {
        $AdvancedExpander.IsExpanded = $true
        Set-Status "Download complete" "The Opus files are ready, but Picard.exe was not found. Set the Picard path and tag manually." "Needs Picard"
        Write-Log "Picard not found. Audio download is complete."
        Set-Busy $false
        return
    }

    Set-Status "Tagging with Picard" "Clustering the album, looking it up on MusicBrainz, and saving matched tags." "Tagging"
    $OverallProgress.IsIndeterminate = $true
    $TrackStatusText.Text = "MusicBrainz lookup…"
    Write-Log "Starting MusicBrainz Picard automation."

    $picardArgs = @(
        "-e", "LOAD `"$script:AlbumFolder`"",
        "-e", "CLUSTER",
        "-e", "LOOKUP_CLUSTERED",
        "-e", "PAUSE 12",
        "-e", "SAVE_MATCHED",
        "-e", "REMOVE_SAVED",
        "-e", "REMOVE_EMPTY",
        "-e", "SHOW"
    )

    try {
        Start-Process -FilePath $PicardBox.Text -ArgumentList $picardArgs | Out-Null
        $script:PicardFinishAt = (Get-Date).AddSeconds(15)
        $script:JobMode = "picardwait"
    } catch {
        Write-Log "Picard launch failed: $($_.Exception.Message)"
        Set-Status "Picard error" $_.Exception.Message "Error"
        Set-Busy $false
    }
}

function Finish-All {
    $OverallProgress.IsIndeterminate = $false
    $OverallProgress.Value = 100
    $TrackStatusText.Text = "Complete"
    Set-Status "Album ready" "Download and tagging workflow finished." "Complete"
    Write-Log "Finished."
    Set-Busy $false

    if ([bool]$OpenFolderCheck.IsChecked -and (Test-Path $script:AlbumFolder)) {
        Start-Process explorer.exe -ArgumentList @($script:AlbumFolder)
    }
}

function Process-ResolveResult {
    param([string[]]$Lines)

    $Lines | ForEach-Object { Write-Log $_ }
    $all = ($Lines -join "`n")

    $m = [regex]::Match(
        $all,
        'Redirecting to\s+(https://www\.youtube\.com/[^\s]+)',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )

    if (-not $m.Success) {
        $Lines | ForEach-Object { Write-Log $_ }
        throw "yt-dlp did not return a redirected YouTube URL."
    }

    $redirected = $m.Groups[1].Value.Trim().TrimEnd('.', ',', ';', ')')
    $script:ResolvedUrl = $redirected

    Write-Log "Redirected URL captured."
    Write-Log "Using: $redirected"

    $UrlBox.Text = $redirected
    $UrlBox.CaretIndex = $UrlBox.Text.Length

    $script:ResolvedUrl = $redirected
    $script:PendingPreviewAfterResolve = $false

    Set-Busy $false
    $OverallProgress.IsIndeterminate = $false

    Start-Preview
}

function Process-PreviewResult {
    param([string[]]$Lines)

    $joined = ($Lines | Where-Object { $_ -notmatch "^__OPUSBOX_EXITCODE__=" }) -join "`n"
    try {
        $info = $joined | ConvertFrom-Json
    } catch {
        throw "yt-dlp did not return valid playlist information. Open View log for details."
    }

    $title = [string]$info.title
    if ([string]::IsNullOrWhiteSpace($title)) { $title = [string]$info.playlist_title }
    if ([string]::IsNullOrWhiteSpace($title)) { $title = "YouTube Album" }
    $script:AlbumTitle = $title

    $entries = @($info.entries)
    $script:TrackCount = $entries.Count
    $script:Tracks = @()

    $i = 1
    foreach ($entry in $entries) {
        $t = [string]$entry.title
        if ([string]::IsNullOrWhiteSpace($t)) { $t = "Track $i" }
        $videoId = [string]$entry.id
        if ([string]::IsNullOrWhiteSpace($videoId)) {
            $videoId = [string]$entry.url
            if ($videoId -match '(?:v=|youtu\.be/)([A-Za-z0-9_-]{6,})') {
                $videoId = $matches[1]
            }
        }

        $script:Tracks += [PSCustomObject]@{
            Index   = $i.ToString("00")
            Title   = $t
            VideoId = $videoId
        }
        $i++
    }

    $thumb = ""
    if ($info.thumbnails) {
        $thumbs = @($info.thumbnails)
        if ($thumbs.Count -gt 0) { $thumb = [string]$thumbs[-1].url }
    }
    if ([string]::IsNullOrWhiteSpace($thumb) -and $entries.Count -gt 0 -and $entries[0].thumbnails) {
        $et = @($entries[0].thumbnails)
        if ($et.Count -gt 0) { $thumb = [string]$et[-1].url }
    }
    $script:AlbumThumb = $thumb

    $AlbumTitleText.Text = $script:AlbumTitle
    $AlbumMetaText.Text = "YouTube playlist • ready to download"
    $TrackCountBadge.Text = "$($script:TrackCount) tracks"
    $TrackList.ItemsSource = $script:Tracks
    Set-Cover $script:AlbumThumb
    $OverallProgress.IsIndeterminate = $false
    $OverallProgress.Value = 0
    $TrackStatusText.Text = "Ready"
    Set-Status "Album loaded" "Ready to download. OpusBox will ask about tagging when it finishes." "Ready"
    Write-Log "Loaded '$($script:AlbumTitle)' with $($script:TrackCount) track(s)."

    Set-Busy $false

    if ($script:PendingDownload) {
        $script:PendingDownload = $false
        Start-Download
    }
}

function Get-ArchiveCompletedCount {
    $completed = 0

    if (-not [string]::IsNullOrWhiteSpace($script:ArchiveFile) -and (Test-Path $script:ArchiveFile)) {
        try {
            $completed = @(
                Get-Content -Path $script:ArchiveFile -ErrorAction SilentlyContinue |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            ).Count
        } catch {}
    }

    if ($completed -eq 0 -and (Test-Path $script:AlbumFolder)) {
        try {
            $completed = @(Get-ChildItem -Path $script:AlbumFolder -Filter "*.opus" -File -ErrorAction SilentlyContinue).Count
        } catch {}
    }

    return [Math]::Min($completed, [Math]::Max(0, $script:TrackCount))
}

function Start-DownloadProcessOnly {
    if (-not $script:DownloadArgs -or $script:DownloadArgs.Count -eq 0) {
        throw "Download arguments are not available for watchdog restart."
    }

    $restartArgs = @($script:DownloadArgs)
    if ($script:WatchdogPlaylistStart -gt 1) {
        $url = $restartArgs[$restartArgs.Count - 1]
        $prefix = @($restartArgs | Select-Object -First ($restartArgs.Count - 1))
        $restartArgs = @($prefix) + @("--playlist-start", [string]$script:WatchdogPlaylistStart, $url)
        Write-Log "WATCHDOG: Resume floor is playlist item $($script:WatchdogPlaylistStart); previously skipped stalled items will not be revisited."
    }

    $script:WatchdogRestartPending = $false
    $script:LastArchiveCount = Get-ArchiveCompletedCount
    $script:LastProgressTime = Get-Date

    Write-Log "Watchdog recovery $($script:WatchdogRestarts) of $($script:WatchdogMaxRestarts): resuming with archive protection."
    Set-Status "Restarting stalled download" "yt-dlp stopped making progress. OpusBox is restarting it and will skip a track if the same item stalls twice." "Recovery $($script:WatchdogRestarts)/$($script:WatchdogMaxRestarts)"

    Start-BackgroundCommand -Mode "download" -Exe $YtDlpBox.Text -CommandArgs $restartArgs
}

function Update-LiveDownloadProgress {
    if ($script:JobMode -ne "download" -and $script:JobMode -ne "downloadrecovery") { return }
    if ($script:TrackCount -le 0) { return }

    # Track identity is the YouTube video ID, not the playlist index.
    # Count unique current playlist video IDs that are confirmed present on disk.
    $presentIds = Get-PresentVideoIdSet
    $currentIds = @{}
    foreach ($track in @($script:Tracks)) {
        $id = [string]$track.VideoId
        if (-not [string]::IsNullOrWhiteSpace($id) -and $presentIds.ContainsKey($id)) {
            $currentIds[$id] = $true
        }
    }

    if ($currentIds.Count -gt 0) {
        $completed = $currentIds.Count
    } else {
        # Fallback for unusual playlist entries with no extractor IDs.
        $completed = @(
            Get-ChildItem -Path $script:AlbumFolder -Filter "*.opus" -File -ErrorAction SilentlyContinue |
            Where-Object { $_.BaseName -match '^\s*\d+\s+-\s+' }
        ).Count
    }

    $archiveCompleted = Get-ArchiveCompletedCount
    if ($archiveCompleted -ne $script:LastArchiveCount) {
        $script:LastArchiveCount = $archiveCompleted
        $script:LastProgressTime = Get-Date
    }

    $pct = ($completed / [double]$script:TrackCount) * 100.0
    $OverallProgress.IsIndeterminate = $false
    $OverallProgress.Value = [Math]::Max(0, [Math]::Min(100, $pct))
    $TrackStatusText.Text = "$completed of $($script:TrackCount) complete"

    $elapsed = ((Get-Date) - $script:LastProgressTime).TotalSeconds
    $activeWatchdogSeconds = $script:WatchdogStallSeconds
    if ($completed -eq 0 -and $script:WatchdogRestarts -eq 0) {
        $activeWatchdogSeconds = $script:WatchdogStartupGraceSeconds
    }
    $remaining = [Math]::Max(0, $activeWatchdogSeconds - [int]$elapsed)

    if ($completed -eq 0 -and $script:WatchdogRestarts -eq 0) {
        $StatusTitle.Text = "Preparing download"
        $StatusDetail.Text = "yt-dlp is preparing the playlist and first track. Startup watchdog grace: $([Math]::Ceiling($remaining / 60.0)) min remaining."
        $FooterState.Text = "Starting"
    }

    if ($completed -gt 0) {
        if ($script:JobMode -eq "downloadrecovery") {
            $StatusTitle.Text = "Recovering missing tracks"
        } else {
            $StatusTitle.Text = "Downloading"
        }
        $StatusDetail.Text = "$completed / $($script:TrackCount) tracks complete ($([Math]::Round($pct, 1))%)"
        $FooterState.Text = "$completed / $($script:TrackCount)"
    }

    try {
        $latest = Get-ChildItem -Path $script:AlbumFolder -Filter "*.opus" -File -ErrorAction SilentlyContinue |
                  Sort-Object LastWriteTime -Descending |
                  Select-Object -First 1
        if ($latest) {
            $StatusDetail.Text = "$completed / $($script:TrackCount) tracks complete • Latest: $($latest.BaseName)"
        }
    } catch {}

    if ($script:JobMode -eq "download" -and
        -not $script:WatchdogRestartPending -and
        (-not $script:WatchdogHardStop) -and
        $elapsed -ge $activeWatchdogSeconds) {

        if ($script:WatchdogRestarts -lt $script:WatchdogMaxRestarts) {
            $script:WatchdogRestarts++
            $script:WatchdogRestartPending = $true
            Write-Log "WATCHDOG: No completed track for $activeWatchdogSeconds seconds."
            Write-Log "WATCHDOG: Ending stalled yt-dlp process; recovery $($script:WatchdogRestarts) of $($script:WatchdogMaxRestarts)."
            Set-Status "Stall detected" "No track completed for 3 minutes. Restarting yt-dlp automatically…" "Recovery $($script:WatchdogRestarts)/$($script:WatchdogMaxRestarts)"
            try {
                if ($script:CurrentProcess -and -not $script:CurrentProcess.HasExited) {
                    $script:CurrentProcess.Kill()
                }
            } catch {
                Write-Log "WATCHDOG: Could not kill yt-dlp: $($_.Exception.Message)"
                $script:WatchdogRestartPending = $false
                $script:LastProgressTime = Get-Date
            }
        }
        else {
            $script:WatchdogHardStop = $true
            Write-Log "WATCHDOG: Maximum recovery budget reached."
            Set-Status "Repeated stall" "OpusBox reached its $($script:WatchdogMaxRestarts)-recovery safety limit. The partial download and archive are preserved." "Needs attention"
            try {
                if ($script:CurrentProcess -and -not $script:CurrentProcess.HasExited) {
                    $script:CurrentProcess.Kill()
                }
            } catch {}
        }
    }
}

function Process-DownloadLine {
    param([string]$Line)
    Write-Log $Line

    if ($Line -match "has already been recorded in the archive") {
        $script:SkippedThisRun++
        $script:LastProgressTime = Get-Date
        $TrackStatusText.Text = "Skipping completed track"
        $StatusDetail.Text = "Already downloaded earlier — continuing automatically."
        return
    }

    if ($Line -match "\[download\]\s+Downloading item\s+(\d+)\s+of\s+(\d+)") {
        $ordinal = [int]$matches[1]
        $total = [int]$matches[2]
        if ($script:RecoveryPassActive -and $ordinal -gt 0 -and $ordinal -le $script:RecoveryIndices.Count) {
            $script:CurrentTrack = [int]$script:RecoveryIndices[$ordinal - 1]
        } else {
            $script:CurrentTrack = $ordinal
        }
        if ($total -gt 0 -and -not $script:RecoveryPassActive) {
            $pct = (($script:CurrentTrack - 1) / $total) * 100
            $OverallProgress.Value = [Math]::Max(0, [Math]::Min(99, $pct))
        }
        $TrackStatusText.Text = "Track $($script:CurrentTrack) of $total"
        if ($script:CurrentTrack -le $script:Tracks.Count) {
            $StatusDetail.Text = "Downloading $($script:Tracks[$script:CurrentTrack - 1].Title)"
        }
        return
    }

    if ($Line -match "\[download\]\s+(\d+(?:\.\d+)?)%") {
        $filePct = [double]$matches[1]
        $total = [Math]::Max(1, $script:TrackCount)
        $overall = (([Math]::Max(0, $script:CurrentTrack - 1) + ($filePct / 100.0)) / $total) * 100
        $OverallProgress.Value = [Math]::Max(0, [Math]::Min(99, $overall))
        return
    }

    if ($Line -match "100\.0%|100%") {
        $script:DownloadedThisRun++
        return
    }

    if ($Line -match "ERROR:\s*(.+)$") {
        $reason = $matches[1].Trim()

        if ($reason -match "virtual_file\.log") {
            return
        }

        $trackTitle = ""
        if ($script:CurrentTrack -gt 0 -and $script:CurrentTrack -le $script:Tracks.Count) {
            $trackTitle = [string]$script:Tracks[$script:CurrentTrack - 1].Title
        }

        $script:FailedThisRun.Add([PSCustomObject]@{
            Index  = $script:CurrentTrack
            Title  = $trackTitle
            Reason = $reason
        })
        return
    }
}

function Write-FailedTrackReport {
    if ([string]::IsNullOrWhiteSpace($script:FailedReportPath)) { return }

    $uniqueFailures = @(Get-UniqueFailures)

    if ($uniqueFailures.Count -eq 0) {
        try { Remove-Item $script:FailedReportPath -Force -ErrorAction SilentlyContinue } catch {}
        return
    }

    $report = New-Object System.Collections.Generic.List[string]
    $report.Add("OpusBox Failed Tracks")
    $report.Add("=====================")
    $report.Add("Generated: $(Get-Date)")
    $report.Add("")
    $report.Add("Unique failed items: $($uniqueFailures.Count)")
    $report.Add("")

    foreach ($f in $uniqueFailures) {
        $label = if ($f.Index -gt 0) { "Track $($f.Index)" } else { "Track" }
        if (-not [string]::IsNullOrWhiteSpace([string]$f.Title)) {
            $label += " - $($f.Title)"
        }
        $report.Add($label)
        $report.Add("Reason: $($f.Reason)")
        $report.Add("")
    }

    $report | Set-Content -Path $script:FailedReportPath -Encoding UTF8
    Write-Log "Failed-track report written: $script:FailedReportPath"
}


function Normalize-OpusBoxTrackTitle {
    param([string]$Title)
    if ([string]::IsNullOrWhiteSpace($Title)) { return "" }

    $v = $Title.Trim().ToLowerInvariant()
    $v = [regex]::Replace($v, '\s+', ' ')
    return $v
}

function Load-TrackManifest {
    $items = @()
    if ([string]::IsNullOrWhiteSpace($script:TrackManifestPath)) { return $items }
    if (-not (Test-Path -LiteralPath $script:TrackManifestPath)) { return $items }

    try {
        $raw = Get-Content -LiteralPath $script:TrackManifestPath -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) { return $items }

        $parsed = ConvertFrom-Json -InputObject $raw
        foreach ($entry in @($parsed)) {
            $id = [string]$entry.VideoId
            $path = [string]$entry.Path
            $title = [string]$entry.Title
            if (-not [string]::IsNullOrWhiteSpace($id) -and -not [string]::IsNullOrWhiteSpace($path)) {
                $items += [PSCustomObject]@{
                    VideoId = $id
                    Path    = $path
                    Title   = $title
                }
            }
        }
    } catch {
        Write-Log "WARNING: Could not read track identity manifest: $($_.Exception.Message)"
    }
    return $items
}

function Save-TrackManifest {
    param($Entries)

    if ([string]::IsNullOrWhiteSpace($script:TrackManifestPath)) { return }

    $clean = @(
        @($Entries) |
        Where-Object {
            -not [string]::IsNullOrWhiteSpace([string]$_.VideoId) -and
            -not [string]::IsNullOrWhiteSpace([string]$_.Path)
        } |
        Sort-Object Path -Unique
    )

    try {
        if ($clean.Count -eq 0) {
            "[]" | Set-Content -LiteralPath $script:TrackManifestPath -Encoding UTF8
        } else {
            ConvertTo-Json -InputObject $clean -Depth 4 |
                Set-Content -LiteralPath $script:TrackManifestPath -Encoding UTF8
        }
    } catch {
        Write-Log "WARNING: Could not save track identity manifest: $($_.Exception.Message)"
    }
}

function Refresh-TrackManifestFromDisk {
    $manifest = @(Load-TrackManifest)
    $byPath = @{}

    foreach ($entry in $manifest) {
        $path = [string]$entry.Path
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)) {
            $byPath[$path.ToLowerInvariant()] = [PSCustomObject]@{
                VideoId = [string]$entry.VideoId
                Path    = $path
                Title   = [string]$entry.Title
            }
        }
    }

    # Build a high-confidence title -> video-ID lookup from the current playlist.
    # We only use a title when that normalized title points to exactly one unique video ID.
    $titleIds = @{}
    foreach ($track in @($script:Tracks)) {
        $id = [string]$track.VideoId
        $norm = Normalize-OpusBoxTrackTitle ([string]$track.Title)
        if ([string]::IsNullOrWhiteSpace($id) -or [string]::IsNullOrWhiteSpace($norm)) { continue }

        if (-not $titleIds.ContainsKey($norm)) {
            $titleIds[$norm] = @{}
        }
        $titleIds[$norm][$id] = $true
    }

    $migrationMatches = 0
    foreach ($file in @(Get-ChildItem -Path $script:AlbumFolder -Filter "*.opus" -File -ErrorAction SilentlyContinue)) {
        $pathKey = $file.FullName.ToLowerInvariant()
        if ($byPath.ContainsKey($pathKey)) { continue }

        $fileTitle = $file.BaseName
        if ($fileTitle -match '^\s*\d+\s+-\s+(.+)$') {
            $fileTitle = $matches[1]
        }

        $norm = Normalize-OpusBoxTrackTitle $fileTitle
        if ([string]::IsNullOrWhiteSpace($norm) -or -not $titleIds.ContainsKey($norm)) { continue }

        $candidateIds = @($titleIds[$norm].Keys)
        if ($candidateIds.Count -eq 1) {
            $id = [string]$candidateIds[0]
            $byPath[$pathKey] = [PSCustomObject]@{
                VideoId = $id
                Path    = $file.FullName
                Title   = $fileTitle
            }
            $migrationMatches++
        }
    }

    $result = @($byPath.Values)
    Save-TrackManifest $result

    if ($migrationMatches -gt 0) {
        Write-Log "Identity migration: matched $migrationMatches existing Opus file(s) to unique current YouTube video IDs by title."
    }

    return $result
}

function Import-DownloadMapLog {
    if ([string]::IsNullOrWhiteSpace($script:DownloadMapLog)) { return }
    if (-not (Test-Path -LiteralPath $script:DownloadMapLog)) { return }

    $existing = @(Refresh-TrackManifestFromDisk)
    $byPath = @{}
    foreach ($entry in $existing) {
        $byPath[[string]$entry.Path.ToLowerInvariant()] = $entry
    }

    $imported = 0
    foreach ($line in @(Get-Content -LiteralPath $script:DownloadMapLog -ErrorAction SilentlyContinue)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        # Format: video-id<TAB>playlist-index<TAB>final-path
        $parts = $line -split "`t", 3
        if ($parts.Count -lt 3) { continue }

        $id = [string]$parts[0]
        $path = [string]$parts[2]
        if ([string]::IsNullOrWhiteSpace($id) -or [string]::IsNullOrWhiteSpace($path)) { continue }

        if (-not [System.IO.Path]::IsPathRooted($path)) {
            $path = Join-Path $script:AlbumFolder $path
        }

        if (-not (Test-Path -LiteralPath $path)) { continue }

        $title = [System.IO.Path]::GetFileNameWithoutExtension($path)
        if ($title -match '^\s*\d+\s+-\s+(.+)$') { $title = $matches[1] }

        $byPath[$path.ToLowerInvariant()] = [PSCustomObject]@{
            VideoId = $id
            Path    = $path
            Title   = $title
        }
        $imported++
    }

    Save-TrackManifest @($byPath.Values)
    if ($imported -gt 0) {
        Write-Log "Identity manifest: imported/updated $imported successful yt-dlp mapping record(s)."
    }
}

function Get-PresentVideoIdSet {
    $set = @{}
    foreach ($entry in @(Refresh-TrackManifestFromDisk)) {
        $id = [string]$entry.VideoId
        $path = [string]$entry.Path
        if (-not [string]::IsNullOrWhiteSpace($id) -and
            -not [string]::IsNullOrWhiteSpace($path) -and
            (Test-Path -LiteralPath $path)) {
            $set[$id] = $true
        }
    }
    $script:PresentVideoIds = $set
    return $set
}

function Sync-DownloadArchiveFromManifest {
    if ([string]::IsNullOrWhiteSpace($script:ArchiveFile)) { return }

    $present = Get-PresentVideoIdSet
    if ($present.Count -eq 0) { return }

    $existing = @{}
    if (Test-Path -LiteralPath $script:ArchiveFile) {
        foreach ($line in @(Get-Content -LiteralPath $script:ArchiveFile -ErrorAction SilentlyContinue)) {
            if ($line -match '^\s*youtube\s+([A-Za-z0-9_-]+)\s*$') {
                $existing[$matches[1]] = $true
            }
        }
    }

    $added = 0
    foreach ($id in @($present.Keys)) {
        if (-not $existing.ContainsKey($id)) {
            Add-Content -LiteralPath $script:ArchiveFile -Value ("youtube " + $id) -Encoding UTF8
            $existing[$id] = $true
            $added++
        }
    }

    if ($added -gt 0) {
        Write-Log "Resume archive synchronized with $added video ID(s) confirmed present on disk."
    }
}

function Write-DuplicateTrackReport {
    if ([string]::IsNullOrWhiteSpace($script:AlbumFolder)) { return }

    $reportPath = Join-Path $script:AlbumFolder "OpusBox-Duplicate-Tracks.txt"
    $manifest = @(Refresh-TrackManifestFromDisk)
    $groups = @($manifest | Group-Object VideoId | Where-Object { $_.Count -gt 1 })

    if ($groups.Count -eq 0) {
        try { Remove-Item -LiteralPath $reportPath -Force -ErrorAction SilentlyContinue } catch {}
        return
    }

    $lines = @(
        "OpusBox Duplicate Track Report",
        "==============================",
        "Generated: $(Get-Date)",
        "",
        "Duplicate video-ID groups: $($groups.Count)",
        "No files were deleted automatically.",
        ""
    )

    foreach ($group in $groups) {
        $lines += "YouTube video ID: $($group.Name)"
        foreach ($entry in @($group.Group)) {
            $lines += "  $([string]$entry.Path)"
        }
        $lines += ""
    }

    $lines | Set-Content -LiteralPath $reportPath -Encoding UTF8
    Write-Log "Duplicate report: $($groups.Count) video-ID group(s) found. No files deleted. Report: $reportPath"
}

function Get-LocalPlaylistIndexSet {
    $set = @{}

    if (-not (Test-Path $script:AlbumFolder)) {
        return $set
    }

    Get-ChildItem -Path $script:AlbumFolder -Filter "*.opus" -File -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.BaseName -match '^\s*(\d+)\s+-\s+') {
            $idx = [int]$matches[1]
            if ($idx -gt 0 -and $idx -le $script:TrackCount) {
                $set[$idx] = $true
            }
        }
    }

    return $set
}

function Get-MissingPlaylistIndices {
    $presentIds = Get-PresentVideoIdSet
    $localIndexes = Get-LocalPlaylistIndexSet
    $missing = @()
    $seenIds = @{}

    for ($i = 1; $i -le $script:TrackCount; $i++) {
        $track = if ($i -le $script:Tracks.Count) { $script:Tracks[$i - 1] } else { $null }
        $id = if ($track) { [string]$track.VideoId } else { "" }

        if (-not [string]::IsNullOrWhiteSpace($id)) {
            # One local copy per YouTube video ID is the OpusBox identity rule.
            # If the same video appears multiple times in a playlist, do not create duplicate files.
            if ($seenIds.ContainsKey($id)) { continue }
            $seenIds[$id] = $true

            if (-not $presentIds.ContainsKey($id)) {
                $missing += [int]$i
            }
        }
        else {
            # Fallback for an entry with no extractor ID.
            if (-not $localIndexes.ContainsKey($i)) {
                $missing += [int]$i
            }
        }
    }

    return $missing
}

function Write-UnresolvedTrackReport {
    param([int[]]$Indices)

    if ([string]::IsNullOrWhiteSpace($script:FailedReportPath)) { return }

    $indices = @($Indices | Sort-Object -Unique)
    if ($indices.Count -eq 0) {
        try { Remove-Item $script:FailedReportPath -Force -ErrorAction SilentlyContinue } catch {}
        return
    }

    $report = New-Object System.Collections.Generic.List[string]
    $report.Add("OpusBox Unresolved Tracks")
    $report.Add("=========================")
    $report.Add("Generated: $(Get-Date)")
    $report.Add("")
    $report.Add("Playlist items still unresolved after the automatic second pass: $($indices.Count)")
    $report.Add("")

    foreach ($idx in $indices) {
        $title = if ($idx -gt 0 -and $idx -le $script:Tracks.Count) {
            [string]$script:Tracks[$idx - 1].Title
        } else {
            ""
        }

        $label = "Track $idx"
        if (-not [string]::IsNullOrWhiteSpace($title)) {
            $label += " - $title"
        }

        $report.Add($label)
        $report.Add("Reason: No Opus file exists after the primary download and one automatic targeted retry.")
        $report.Add("")
    }

    $report | Set-Content -Path $script:FailedReportPath -Encoding UTF8
    Write-Log "Unresolved-track report written: $script:FailedReportPath"
}

function Start-MissingTrackRecovery {
    param([int[]]$MissingIndices)

    $missing = @($MissingIndices | Sort-Object -Unique)
    if ($missing.Count -eq 0) { return $false }

    $script:RecoveryPassActive = $true
    $script:RecoveryIndices = @($missing)
    $script:RecoveryInitialCount = $missing.Count
    $script:WatchdogRestartPending = $false
    $script:WatchdogHardStop = $false
    $script:WatchdogLastStallTrack = 0
    $script:WatchdogSameTrackStalls = 0
    $script:WatchdogPlaylistStart = 0
    $script:LastArchiveCount = Get-ArchiveCompletedCount
    $script:LastProgressTime = Get-Date

    $baseArgs = @($script:PrimaryDownloadArgs)
    if ($baseArgs.Count -lt 1) {
        throw "Primary download arguments are unavailable for recovery."
    }

    $url = $baseArgs[$baseArgs.Count - 1]
    $prefix = @($baseArgs | Select-Object -First ($baseArgs.Count - 1))

    # Recovery intentionally ignores the normal download archive.
    # If the expected .opus file is missing on disk, retry it even if an older
    # archive entry says the video was downloaded previously.
    $cleanPrefix = New-Object System.Collections.Generic.List[string]
    for ($i = 0; $i -lt $prefix.Count; $i++) {
        if ($prefix[$i] -eq "--download-archive") {
            $i++
            continue
        }
        $cleanPrefix.Add([string]$prefix[$i])
    }

    $selector = ($missing -join ",")
    $recoveryArgs = @($cleanPrefix) + @("--playlist-items", $selector, $url)

    Write-Log "RECOVERY: Primary pass left $($missing.Count) playlist item(s) without Opus files."
    Write-Log "RECOVERY: Ignoring the normal yt-dlp archive because these files are missing on disk."
    Write-Log "RECOVERY: Starting one targeted second pass for only the missing playlist indexes."
    if ($missing.Count -le 30) {
        Write-Log "RECOVERY: Missing indexes: $selector"
    } else {
        Write-Log "RECOVERY: Missing index list contains $($missing.Count) entries."
    }

    Set-Status "Recovery pass" "Retrying $($missing.Count) missing track(s) before declaring the playlist finished." "Second pass"
    $TrackStatusText.Text = "Retrying $($missing.Count) missing track(s)"
    $FooterState.Text = "Recovery pass"

    Start-BackgroundCommand -Mode "downloadrecovery" -Exe $YtDlpBox.Text -CommandArgs $recoveryArgs
    return $true
}

function Get-UniqueFailures {
    $unique = @()
    $seen = @{}

    foreach ($f in @($script:FailedThisRun)) {
        $idx = [int]$f.Index
        $reason = [string]$f.Reason
        $title = [string]$f.Title

        if ($idx -gt 0) {
            $key = "idx:$idx"
        }
        else {
            $key = "text:$($title.ToLowerInvariant())|$($reason.ToLowerInvariant())"
        }

        if (-not $seen.ContainsKey($key)) {
            $seen[$key] = $true
            $unique += ,$f
        }
    }

    return $unique
}

function Get-NewFilesForTagging {
    $newFiles = @(
        Get-ChildItem -Path $script:AlbumFolder -Filter "*.opus" -File -ErrorAction SilentlyContinue |
        Sort-Object FullName |
        Where-Object {
            $key = $_.FullName.ToLowerInvariant()
            -not $script:NewFilesBeforeRun.ContainsKey($key)
        }
    )

    return $newFiles
}

function ConvertTo-WindowsCommandLineArgument {
    param([string]$Argument)

    if ($null -eq $Argument) { return '""' }
    if ($Argument -notmatch '[\s"]') { return $Argument }

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('"')
    $slashes = 0

    foreach ($ch in $Argument.ToCharArray()) {
        if ($ch -eq '\') {
            $slashes++
            continue
        }

        if ($ch -eq '"') {
            if ($slashes -gt 0) {
                [void]$sb.Append(('\' * ($slashes * 2)))
                $slashes = 0
            }
            [void]$sb.Append('\\"')
            continue
        }

        if ($slashes -gt 0) {
            [void]$sb.Append(('\' * $slashes))
            $slashes = 0
        }

        [void]$sb.Append($ch)
    }

    if ($slashes -gt 0) {
        [void]$sb.Append(('\' * ($slashes * 2)))
    }

    [void]$sb.Append('"')
    return $sb.ToString()
}

function ConvertTo-FileUri {
    param([Parameter(Mandatory=$true)][string]$Path)

    $full = [System.IO.Path]::GetFullPath($Path)
    $uri = New-Object System.Uri($full)
    return $uri.AbsoluteUri
}

function Start-PicardDirectCommands {
    param(
        [Parameter(Mandatory=$true)][string[]]$Commands
    )

    if (-not (Test-Path $PicardBox.Text)) {
        throw "Picard.exe was not found."
    }

    $argv = New-Object System.Collections.Generic.List[string]
    foreach ($cmd in $Commands) {
        $argv.Add("-e")
        $argv.Add([string]$cmd)
    }

    $argumentLine = ($argv | ForEach-Object {
        ConvertTo-WindowsCommandLineArgument ([string]$_)
    }) -join ' '

    Write-Log "Launching Picard with $($Commands.Count) direct executable command(s)."
    foreach ($cmd in $Commands) {
        Write-Log "Picard -e: $cmd"
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $PicardBox.Text
    $psi.Arguments = $argumentLine
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.WorkingDirectory = Split-Path $PicardBox.Text -Parent

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    if (-not $proc.Start()) {
        throw "Picard could not be started."
    }

    try { $proc.Dispose() } catch {}
}

function Start-PicardFilesAndCommands {
    param(
        [string[]]$Files = @(),
        [string[]]$Commands = @()
    )

    if (-not (Test-Path $PicardBox.Text)) {
        throw "Picard.exe was not found."
    }

    $argv = New-Object System.Collections.Generic.List[string]

    foreach ($cmd in $Commands) {
        $argv.Add("-e")
        $argv.Add([string]$cmd)
    }

    if ($Files.Count -gt 0) {
        $argv.Add("--")

        foreach ($file in $Files) {
            if (-not (Test-Path $file)) {
                throw "Audio file was not found: $file"
            }

            $argv.Add([System.IO.Path]::GetFullPath($file))
        }
    }

    $argumentLine = ($argv | ForEach-Object {
        ConvertTo-WindowsCommandLineArgument ([string]$_)
    }) -join ' '

    Write-Log "Launching Picard: $($Commands.Count) command(s), then $($Files.Count) positional file(s)."
    Write-Log "Picard argv boundary: -- before file arguments."

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $PicardBox.Text
    $psi.Arguments = $argumentLine
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.WorkingDirectory = Split-Path $PicardBox.Text -Parent

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    if (-not $proc.Start()) {
        throw "Picard could not be started."
    }

    try { $proc.Dispose() } catch {}
}

function Submit-PicardBatches {
    param(
        [Parameter(Mandatory=$true)][System.IO.FileInfo[]]$Files,
        [Parameter(Mandatory=$true)][int]$BatchSize,
        [Parameter(Mandatory=$true)][int]$WaitSeconds
    )

    if ($Files.Count -eq 0) { return 0 }

    $batchCount = [Math]::Ceiling($Files.Count / [double]$BatchSize)

    for ($offset = 0; $offset -lt $Files.Count; $offset += $BatchSize) {
        $batchNumber = [int]($offset / $BatchSize) + 1
        $end = [Math]::Min($offset + $BatchSize - 1, $Files.Count - 1)

        $batchFiles = New-Object System.Collections.Generic.List[string]
        for ($i = $offset; $i -le $end; $i++) {
            $batchFiles.Add($Files[$i].FullName)
        }

        $commands = @(
            "SHOW",
            "PAUSE 3",
            "SCAN",
            "PAUSE $WaitSeconds",
            "SAVE_MATCHED",
            "PAUSE 3",
            "REMOVE_SAVED",
            "REMOVE_EMPTY",
            "REMOVE_UNCLUSTERED"
        )

        Write-Log "Submitting Picard batch $batchNumber of $batchCount ($($batchFiles.Count) file(s))."
        Start-PicardFilesAndCommands -Files @($batchFiles) -Commands $commands
    }

    return [int]$batchCount
}

function Start-PicardCommandFile {
    param(
        [Parameter(Mandatory=$true)][string]$CommandFile
    )

    if (-not (Test-Path $PicardBox.Text)) {
        throw "Picard.exe was not found."
    }
    if (-not (Test-Path $CommandFile)) {
        throw "Picard command file was not found: $CommandFile"
    }

    $commandFileUri = ConvertTo-FileUri $CommandFile
    $fromFileCommand = 'FROM_FILE "' + $commandFileUri + '"'
    $argv = @(
        '-e',
        $fromFileCommand,
        '-e',
        'SHOW'
    )

    $argumentLine = ($argv | ForEach-Object {
        ConvertTo-WindowsCommandLineArgument ([string]$_)
    }) -join ' '

    Write-Log "Picard command file: $CommandFile"
    Write-Log "Launching Picard command processor."

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $PicardBox.Text
    $psi.Arguments = $argumentLine
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.WorkingDirectory = Split-Path $PicardBox.Text -Parent

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    if (-not $proc.Start()) {
        throw "Picard could not be started."
    }

    try { $proc.Dispose() } catch {}
}


function Start-AutomaticPicardQueueWorker {
    param(
        [Parameter(Mandatory=$true)]$Files,
        [Parameter(Mandatory=$true)][int]$BatchSize,
        [Parameter(Mandatory=$true)][int]$WaitSeconds
    )
    $Files = @($Files | Where-Object { $null -ne $_ })

    if ($Files.Count -eq 0) {
        throw "No files were supplied to the Picard queue."
    }
    if (-not (Test-Path $PicardBox.Text)) {
        throw "Picard.exe was not found."
    }

    $oldWorkers = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and $_.CommandLine -match 'picard-queue-[0-9]{8}-[0-9]{6}(?:-[0-9]{3})?\.ps1' })
    if ($oldWorkers.Count -gt 0) {
        $workerPids = ($oldWorkers | ForEach-Object { [string]$_.ProcessId }) -join ", "
        throw "Another OpusBox Picard queue is already running (PID: $workerPids). Finish or stop that queue before starting another."
    }

    $commandDir = Join-Path $env:APPDATA "OpusBox"
    if (-not (Test-Path $commandDir)) {
        New-Item -ItemType Directory -Path $commandDir -Force | Out-Null
    }

    $stamp = Get-Date -Format "yyyyMMdd-HHmmss-fff"
    $workerPath = Join-Path $commandDir ("picard-queue-" + $stamp + ".ps1")
    $listPath = Join-Path $commandDir ("picard-queue-" + $stamp + "-files.json")
    $queueLog = Join-Path $commandDir ("picard-queue-" + $stamp + ".log")

    $filePathArray = @($Files | ForEach-Object { [string]$_.FullName })
    ConvertTo-Json -InputObject $filePathArray -Compress |
        Set-Content -Path $listPath -Encoding UTF8

    $workerScript = @'
param(
    [Parameter(Mandatory=$true)][string]$Picard,
    [Parameter(Mandatory=$true)][string]$ListPath,
    [Parameter(Mandatory=$true)][string]$LogPath,
    [Parameter(Mandatory=$true)][int]$WaitSeconds,
    [Parameter(Mandatory=$true)][int]$BatchSize
)

$ErrorActionPreference = "Stop"

function Log([string]$Text) {
    $line = "[$(Get-Date -Format HH:mm:ss)] $Text"
    Add-Content -Path $LogPath -Value $line -Encoding UTF8
}

function Quote-Arg([string]$Argument) {
    if ($null -eq $Argument) { return '""' }
    if ($Argument -notmatch '[\s"]') { return $Argument }

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('"')
    $slashes = 0

    foreach ($ch in $Argument.ToCharArray()) {
        if ($ch -eq '\') {
            $slashes++
            continue
        }

        if ($ch -eq '"') {
            if ($slashes -gt 0) {
                [void]$sb.Append(('\' * ($slashes * 2)))
                $slashes = 0
            }
            [void]$sb.Append('\\"')
            continue
        }

        if ($slashes -gt 0) {
            [void]$sb.Append(('\' * $slashes))
            $slashes = 0
        }

        [void]$sb.Append($ch)
    }

    if ($slashes -gt 0) {
        [void]$sb.Append(('\' * ($slashes * 2)))
    }

    [void]$sb.Append('"')
    return $sb.ToString()
}

function Run-Picard([string[]]$Files, [string[]]$Commands) {
    $argv = New-Object System.Collections.Generic.List[string]

    foreach ($cmd in $Commands) {
        $argv.Add("-e")
        $argv.Add([string]$cmd)
    }

    if ($Files.Count -gt 0) {
        $argv.Add("--")
        foreach ($f in $Files) {
            $pathText = [string]$f
            if ([string]::IsNullOrWhiteSpace($pathText)) {
                Log "WARNING: Skipping empty queued audio path."
                continue
            }
            if (-not (Test-Path -LiteralPath $pathText)) {
                Log "WARNING: Skipping missing queued audio file: $pathText"
                continue
            }
            $argv.Add([System.IO.Path]::GetFullPath($pathText))
        }
    }

    if ($argv.Count -eq $Commands.Count * 2 + 1 -and $Files.Count -gt 0) {
        Log "WARNING: No valid audio files remained in this Picard command submission."
        return
    }

    $line = ($argv | ForEach-Object { Quote-Arg ([string]$_) }) -join " "

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Picard
    $psi.Arguments = $line
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.WorkingDirectory = Split-Path $Picard -Parent

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi

    if (-not $p.Start()) {
        throw "Could not start Picard."
    }

    $senderPid = $p.Id
    if ($p.WaitForExit(5000)) {
        Log "Picard batch handoff completed (sender PID $senderPid exited)."
    } else {
        Log "Picard batch process PID $senderPid remains active; continuing after command submission."
    }
    try { $p.Dispose() } catch {}
}

try {
    Log "Worker process started."
    Log "Picard path: $Picard"
    Log "File list: $ListPath"

    if (-not (Test-Path $Picard)) {
        throw "Picard.exe not found at: $Picard"
    }

    if (-not (Test-Path $ListPath)) {
        throw "File list not found at: $ListPath"
    }

    Log "Picard will be started by the first real batch submission; no separate primary GUI is pre-launched."

    $json = Get-Content -Path $ListPath -Raw
    $parsed = ConvertFrom-Json -InputObject $json
    $Files = @($parsed | ForEach-Object { [string]$_ })

    if ($Files.Count -eq 0) {
        throw "The queue file list was empty."
    }

    Log "Parsed file count: $($Files.Count)"
    Log "First file: $($Files[0])"

    $BatchCount = [int][Math]::Ceiling($Files.Count / [double]$BatchSize)
    Log "Queue started: $($Files.Count) files, $BatchCount batches."

    for ($offset = 0; $offset -lt $Files.Count; $offset += $BatchSize) {
        $batchNumber = [int]($offset / $BatchSize) + 1
        $batch = @($Files | Select-Object -Skip $offset -First $BatchSize)
        $batch = @($batch | Where-Object {
            $p = [string]$_
            if ([string]::IsNullOrWhiteSpace($p)) {
                Log "WARNING: Skipping empty path in batch $batchNumber."
                return $false
            }
            if (-not (Test-Path -LiteralPath $p)) {
                Log "WARNING: Skipping missing file in batch ${batchNumber}: $p"
                return $false
            }
            return $true
        })

        if ($batch.Count -eq 0) {
            Log "Batch ${batchNumber} / ${BatchCount}: no valid files remain; skipping batch."
            continue
        }

        Log "Batch ${batchNumber} / ${BatchCount}: loading $($batch.Count) valid files."
        Log "Batch first path: $($batch[0])"

        Run-Picard -Files $batch -Commands @(
            "SHOW",
            "PAUSE 2",
            "SCAN",
            "PAUSE $WaitSeconds",
            "SAVE_MATCHED",
            "PAUSE 8",
            "SAVE_MATCHED",
            "PAUSE 2",
            "REMOVE_SAVED",
            "REMOVE_EMPTY",
            "REMOVE_UNCLUSTERED"
        )

        Log "Batch ${batchNumber} / ${BatchCount}: scan/save command queue submitted."
        Log "Batch ${batchNumber} / ${BatchCount}: waiting for Picard to finish matching, artwork and saves."
        Start-Sleep -Seconds ($WaitSeconds + 16)
        Log "Batch ${batchNumber} / ${BatchCount} complete."
    }

    Log "Queue complete."
}
catch {
    try {
        Log ("FATAL: " + $_.Exception.Message)
        Log ("STACK: " + $_.ScriptStackTrace)
    } catch {}
    exit 1
}
'@

    $workerScript | Set-Content -Path $workerPath -Encoding UTF8

    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $workerPath,
        [ref]$tokens,
        [ref]$parseErrors
    )
    if ($parseErrors -and $parseErrors.Count -gt 0) {
        $msg = ($parseErrors | ForEach-Object {
            "Line $($_.Extent.StartLineNumber): $($_.Message)"
        }) -join "`r`n"
        throw "Generated Picard worker has a PowerShell parse error:`r`n$msg"
    }

    $args = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-WindowStyle", "Hidden",
        "-File", $workerPath,
        "-Picard", $PicardBox.Text,
        "-ListPath", $listPath,
        "-LogPath", $queueLog,
        "-WaitSeconds", [string]$WaitSeconds,
        "-BatchSize", [string]$BatchSize
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = Convert-ToProcessArgumentString $args
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    if (-not $proc.Start()) {
        throw "Could not start the Picard queue worker."
    }

    Start-Sleep -Milliseconds 1200
    if ($proc.HasExited) {
        $details = ""
        if (Test-Path $queueLog) {
            $details = [string](Get-Content $queueLog -Raw -ErrorAction SilentlyContinue)
        }
        if ([string]::IsNullOrWhiteSpace($details)) {
            $details = "Worker exited immediately with code $($proc.ExitCode)."
        }
        throw "Picard queue worker stopped immediately:`r`n`r`n$details"
    }

    return [PSCustomObject]@{
        Process = $proc
        LogPath = $queueLog
        WorkerPath = $workerPath
        ListPath = $listPath
        BatchCount = [int][Math]::Ceiling($Files.Count / [double]$BatchSize)
    }
}

function Confirm-PostDownloadTagging {
    param($Files)
    $Files = @($Files | Where-Object { $null -ne $_ })

    if (-not (Test-Path $PicardBox.Text)) {
        Write-Log "Picard not found at post-download handoff."
        Finish-DownloadWorkflow $Files.Count 0
        return
    }

    $taggingExisting = $false
    if ($Files.Count -eq 0) {
        $Files = @(
            Get-ChildItem -Path $script:AlbumFolder -Filter "*.opus" -File -ErrorAction SilentlyContinue |
            Sort-Object FullName
        )
        $taggingExisting = $true
    }

    if ($Files.Count -eq 0) {
        Write-Log "Post-download tagging: no Opus files exist to tag."
        Finish-DownloadWorkflow 0 0
        return
    }

    Write-Log "Post-download tagging prompt: $($Files.Count) file(s) passed validation/binding."

    if ($taggingExisting) {
        $message = "Download check complete.`r`n`r`nNo new Opus files were downloaded, but $($Files.Count) existing Opus file(s) are present.`r`n`r`nTag the existing files with MusicBrainz Picard now?"
    } else {
        $message = "Download complete.`r`n`r`n$($Files.Count) new Opus file(s) are ready.`r`n`r`nReady to tag them with MusicBrainz Picard now?"
    }

    $a=[System.Windows.MessageBox]::Show(
        $message,
        "OpusBox - Ready to Tag?",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question)

    if ($a -eq [System.Windows.MessageBoxResult]::Yes) {
        if ($taggingExisting) {
            Write-Log "User chose to tag existing Opus files after a no-new-files download check."
        } else {
            Write-Log "User chose post-download tagging."
        }
        Start-AutomaticBatchTagging -Files $Files
    } else {
        Write-Log "User skipped post-download tagging."
        Finish-DownloadWorkflow 0 0
    }
}

function Start-AutomaticBatchTagging {
    param($Files)
    $Files = @($Files | Where-Object { $null -ne $_ })

    if ($Files.Count -eq 0) {
        Finish-DownloadWorkflow 0 0
        return
    }

    if (-not (Test-Path $PicardBox.Text)) {
        Write-Log "Picard not found; skipping post-download tagging."
        Finish-DownloadWorkflow $Files.Count 0
        return
    }

    $verifiedFiles = @()
    foreach ($file in @($Files)) {
        if ($null -eq $file) { continue }

        $pathText = [string]$file.FullName
        if ([string]::IsNullOrWhiteSpace($pathText)) { continue }

        if (Test-Path -LiteralPath $pathText) {
            $verifiedFiles += ,(Get-Item -LiteralPath $pathText)
        } else {
            Write-Log "WARNING: Skipping missing Picard queue file before launch: $pathText"
        }
    }

    $Files = $verifiedFiles
    if ($Files.Count -eq 0) {
        Write-Log "No existing files remained for Picard after validation."
        Finish-DownloadWorkflow 0 0
        return
    }

    $batchSize = $script:TagBatchSize
    $waitSeconds = $script:TagWaitSeconds
    $batchCount = [int][Math]::Ceiling($Files.Count / [double]$batchSize)

    Set-Status "Batch tagging new music" "Starting a sequential Picard queue for $($Files.Count) verified file(s) in $batchCount batch(es)." "Tagging"
    $TrackStatusText.Text = "$($Files.Count) verified file(s) queued for tagging"
    Write-Log "Automatic Picard tagging: $($Files.Count) verified file(s), $batchCount batch(es)."

    $queue = Start-AutomaticPicardQueueWorker -Files $Files -BatchSize $batchSize -WaitSeconds $waitSeconds

    $script:AutoPicardProcess = $queue.Process
    $script:AutoPicardLogPath = [string]$queue.LogPath
    $script:AutoPicardLogCache = ""
    $script:AutoPicardNewFiles = $Files.Count
    $script:AutoPicardBatchCount = [int]$queue.BatchCount
    $script:JobMode = "autopicard"

    Write-Log "Automatic Picard queue worker: $($queue.WorkerPath)"
    Write-Log "Automatic Picard queue log: $($queue.LogPath)"
    Write-Log "Automatic Picard file list: $($queue.ListPath)"
}

function Finish-DownloadWorkflow {
    param(
        [int]$NewFiles,
        [int]$TagBatches
    )

    Write-Log "Finalizing download workflow."
    Write-FailedTrackReport
    Write-Log "Finalization: failed-track report complete."
    $uniqueFailures = @(Get-UniqueFailures)
    Write-Log "Finalization: unique failure count = $($uniqueFailures.Count)."

    $afterIndices = Get-LocalPlaylistIndexSet
    Write-Log "Finalization: local playlist index scan complete."
    $alreadyPresent = 0
    $newPositions = 0
    $unresolved = 0

    for ($i = 1; $i -le $script:TrackCount; $i++) {
        $wasThere = $script:ExistingIndicesBeforeRun.ContainsKey($i)
        $isThere = $afterIndices.ContainsKey($i)

        if ($wasThere -and $isThere) {
            $alreadyPresent++
        }
        elseif ((-not $wasThere) -and $isThere) {
            $newPositions++
        }
        else {
            $unresolved++
        }
    }

    $accounted = $alreadyPresent + $newPositions + $unresolved

    $OverallProgress.IsIndeterminate = $false
    $OverallProgress.Value = 100
    $TrackStatusText.Text = "Complete"

    $summary = "New: $newPositions • Already present: $alreadyPresent • Unresolved: $unresolved"
    if ($TagBatches -gt 0) {
        $summary += " • Picard batches submitted: $TagBatches"
    }

    Set-Status "Sync complete" $summary "Accounted: $accounted / $($script:TrackCount)"
    Write-Log "Sync summary: $summary"
    Write-Log "Playlist accounting: $accounted / $($script:TrackCount) entries."
    Write-Log "New file snapshot used for tagging: $NewFiles file(s)."

    if ($uniqueFailures.Count -gt 0) {
        Write-Log "Unique yt-dlp/watchdog errors observed: $($uniqueFailures.Count)"
        Write-Log "Review failures at: $script:FailedReportPath"
    }

    if ($unresolved -gt 0) {
        Write-Log "Unresolved means no numbered Opus file exists for that playlist position after the run. This can include unavailable/private/deleted items, genuine failures, or locally removed files whose IDs remain archived."
    }

    Set-Busy $false

    if ([bool]$OpenFolderCheck.IsChecked -and (Test-Path $script:AlbumFolder)) {
        Start-Process explorer.exe -ArgumentList @($script:AlbumFolder)
    }
}

$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(200)
$timer.Add_Tick({
    if ($script:JobMode -eq "autopicard") {
        try {
            if ($script:AutoPicardLogPath -and (Test-Path $script:AutoPicardLogPath)) {
                $nowText = [string](Get-Content -Path $script:AutoPicardLogPath -Raw -ErrorAction SilentlyContinue)
                if ($nowText -ne $script:AutoPicardLogCache) {
                    $script:AutoPicardLogCache = $nowText

                    $lastLine = @($nowText -split "\r?\n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Last 1)
                    if ($lastLine.Count -gt 0) {
                        $StatusDetail.Text = [string]$lastLine[0]
                    }

                    $batchMatches = [regex]::Matches($nowText, 'Batch\s+(\d+)\s+/\s+(\d+)')
                    if ($batchMatches.Count -gt 0) {
                        $latestBatch = $batchMatches[$batchMatches.Count - 1]
                        $TrackStatusText.Text = "Picard batch $($latestBatch.Groups[1].Value) of $($latestBatch.Groups[2].Value)"
                    }
                }
            }

            $queueComplete = ($script:AutoPicardLogCache -match 'Queue complete\.')
            $workerExited = $false
            if ($script:AutoPicardProcess) {
                try { $workerExited = $script:AutoPicardProcess.HasExited } catch {}
            }

            if ($queueComplete -or $workerExited) {
                $exitCode = 0
                if ($script:AutoPicardProcess -and $workerExited) {
                    try { $exitCode = $script:AutoPicardProcess.ExitCode } catch {}
                }

                try {
                    if ($script:AutoPicardProcess) { $script:AutoPicardProcess.Dispose() }
                } catch {}
                $script:AutoPicardProcess = $null
                $script:JobMode = ""

                if ($queueComplete -and $exitCode -eq 0) {
                    Write-Log "Automatic Picard queue complete."
                    Finish-DownloadWorkflow $script:AutoPicardNewFiles $script:AutoPicardBatchCount
                } else {
                    Write-Log "Automatic Picard queue stopped before completion. Log: $($script:AutoPicardLogPath)"
                    Set-Status "Picard queue stopped" "The tagging worker ended before Queue complete. Review the Picard queue log." "Tagging error"
                    $TrackStatusText.Text = "Picard tagging stopped"
                    Set-Busy $false
                }
            }
        }
        catch {
            Write-Log "Automatic Picard monitor error: $($_.Exception.Message)"
        }
        return
    }

    if ($script:JobMode -eq "picardwait") {
        if ($script:PicardFinishAt -and (Get-Date) -ge $script:PicardFinishAt) {
            $script:JobMode = ""
            Finish-All
        }
        return
    }

    if (-not $script:CurrentProcess) { return }

    if (-not $script:CurrentProcess.HasExited) {
        if ($script:JobMode -eq "resolve") {
            $FooterState.Text = "Resolving YouTube Music link…"
        }
        elseif ($script:JobMode -eq "preview") {
            $FooterState.Text = "Reading album…"
        }
        elseif ($script:JobMode -eq "cookieimport") {
            $FooterState.Text = "Connecting YouTube..."
        }
        elseif ($script:JobMode -eq "cookievalidate") {
            $FooterState.Text = "Verifying YouTube..."
        }
        elseif ($script:JobMode -eq "download" -or $script:JobMode -eq "downloadrecovery") {
            Update-LiveDownloadProgress
        }
        return
    }

    if ($script:StdoutTask -and -not $script:StdoutTask.IsCompleted) { return }
    if ($script:StderrTask -and -not $script:StderrTask.IsCompleted) { return }

    $mode = $script:JobMode
    $exitCode = $script:CurrentProcess.ExitCode

    $stdout = ""
    $stderr = ""
    try {
        if ($script:StdoutTask) { $stdout = [string]$script:StdoutTask.GetAwaiter().GetResult() }
    } catch {}
    try {
        if ($script:StderrTask) { $stderr = [string]$script:StderrTask.GetAwaiter().GetResult() }
    } catch {}

    $stdoutLines = @()
    $stderrLines = @()

    if (-not [string]::IsNullOrWhiteSpace($stdout)) {
        $stdoutLines = @($stdout -split "\r?\n" | Where-Object { $_ -ne "" })
    }

    if (-not [string]::IsNullOrWhiteSpace($stderr)) {
        $stderrLines = @($stderr -split "\r?\n" | Where-Object { $_ -ne "" })
    }

    $allLines = @($stdoutLines) + @($stderrLines)

    $youtubeAuthRejected = (($allLines -join "`n") -match "Sign in to confirm you.?re not a bot")
    if ($youtubeAuthRejected -and $mode -ne "cookieimport" -and $mode -ne "cookievalidate") {
        Write-Log "YOUTUBE AUTH: YouTube requested a signed-in session. Use Connect YouTube under Advanced settings."
        $AdvancedExpander.IsExpanded = $true
        $YouTubeAuthStatusText.Text = "Login needs refresh"
        $YouTubeAuthStatusText.Foreground = [Windows.Media.Brushes]::Goldenrod
        $YouTubeAuthDetailText.Text = "YouTube rejected this session. Click Refresh to reconnect."
        $ConnectYouTubeButton.Content = "Refresh"
    }

    try { $script:CurrentProcess.Dispose() } catch {}
    $script:CurrentProcess = $null
    $script:StdoutTask = $null
    $script:StderrTask = $null
    $script:JobMode = ""

    if ($mode -eq "download" -and $script:WatchdogRestartPending) {
        try {
            $allLines | ForEach-Object { Process-DownloadLine ([string]$_) }

            $stalledTrack = [int]$script:CurrentTrack
            if ($stalledTrack -gt 0) {
                if ($script:WatchdogLastStallTrack -eq $stalledTrack) {
                    $script:WatchdogSameTrackStalls++
                } else {
                    $script:WatchdogLastStallTrack = $stalledTrack
                    $script:WatchdogSameTrackStalls = 1
                }

                $title = if ($stalledTrack -le $script:Tracks.Count) { [string]$script:Tracks[$stalledTrack - 1].Title } else { "playlist item $stalledTrack" }
                Write-Log "WATCHDOG: Stalled item #$stalledTrack - $title (stall $($script:WatchdogSameTrackStalls) on this item)."

                if ($script:WatchdogSameTrackStalls -ge 2) {
                    $script:WatchdogPlaylistStart = $stalledTrack + 1
                    Write-Log "WATCHDOG: Same item stalled twice. Skipping #$stalledTrack - $title and continuing at item $($script:WatchdogPlaylistStart)."
                    $script:FailedThisRun.Add([PSCustomObject]@{
                        Index  = $stalledTrack
                        Title  = $title
                        Reason = "Skipped by OpusBox watchdog after two 3-minute stalls on the same playlist item."
                    })
                    $script:WatchdogLastStallTrack = 0
                    $script:WatchdogSameTrackStalls = 0
                }
            } else {
                Write-Log "WATCHDOG: Could not identify the playlist index from yt-dlp output; retrying from the archive."
            }

            Start-DownloadProcessOnly
        }
        catch {
            $script:WatchdogRestartPending = $false
            Set-Status "Watchdog recovery failed" $_.Exception.Message "Error"
            Write-Log "WATCHDOG ERROR: $($_.Exception.Message)"
            $LogExpander.IsExpanded = $true
            Set-Busy $false
        }
        return
    }

    if ($mode -eq "download" -and $script:WatchdogHardStop) {
        $allLines | ForEach-Object { Process-DownloadLine ([string]$_) }
        Write-FailedTrackReport
        $TrackStatusText.Text = "$(Get-ArchiveCompletedCount) of $($script:TrackCount) complete"
        Set-Status "Download paused" "The watchdog safety limit was reached. Existing files and the archive were preserved; tagging was not started." "Needs attention"
        Set-Busy $false
        return
    }

    try {
        if ($mode -eq "cookievalidate") {
            $ConnectYouTubeButton.IsEnabled = $true
            $combined = $allLines -join "`n"
            $rejected = ($combined -match "Sign in to confirm you.?re not a bot")
            $hasHardError = ($exitCode -ne 0)

            if (-not $rejected -and -not $hasHardError) {
                Update-YouTubeAuthStatus
                $YouTubeAuthStatusText.Text = "Connected"
                $YouTubeAuthStatusText.Foreground = [Windows.Media.Brushes]::LightGreen
                $YouTubeAuthDetailText.Text = "YouTube accepted this saved session for video access."
                $ConnectYouTubeButton.Content = "Refresh"
                $FooterState.Text = "YouTube connected"
                Write-Log "YouTube authentication validated successfully."
                [System.Windows.MessageBox]::Show(
                    "YouTube is connected and verified. You can reopen Chrome now. OpusBox will use this saved session automatically.",
                    "YouTube connected"
                ) | Out-Null
            }
            else {
                $YouTubeAuthStatusText.Text = "Connection failed"
                $YouTubeAuthStatusText.Foreground = [Windows.Media.Brushes]::IndianRed
                $YouTubeAuthDetailText.Text = "The browser session imported, but YouTube still rejected video access."
                $ConnectYouTubeButton.Content = "Retry"
                $FooterState.Text = "YouTube not connected"
                Write-Log "YouTube authentication validation failed."
                $allLines | ForEach-Object { Write-Log ([string]$_) }

                $manual = [System.Windows.MessageBox]::Show(
                    "The browser session imported successfully, but YouTube still rejected it for video access.`r`n`r`nClick Yes to choose an exported YouTube cookies.txt file now, or No to try again later.",
                    "YouTube connection failed",
                    [System.Windows.MessageBoxButton]::YesNo,
                    [System.Windows.MessageBoxImage]::Warning
                )
                if ($manual -eq [System.Windows.MessageBoxResult]::Yes) {
                    $dlg = New-Object System.Windows.Forms.OpenFileDialog
                    $dlg.Filter = "Cookies text file (*.txt)|*.txt|All files (*.*)|*.*"
                    $dlg.Title = "Select exported YouTube cookies.txt"
                    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                        $CookiesBox.Text = $dlg.FileName
                        Save-Settings
                        Start-YouTubeCookieValidation $dlg.FileName
                        return
                    }
                }
            }
        }
        elseif ($mode -eq "cookieimport") {
            $ConnectYouTubeButton.IsEnabled = $true
            if ($exitCode -eq 0 -and
                -not [string]::IsNullOrWhiteSpace($script:CookieImportTemp) -and
                (Test-Path -LiteralPath $script:CookieImportTemp) -and
                ((Get-Item -LiteralPath $script:CookieImportTemp).Length -gt 100)) {

                Move-Item -LiteralPath $script:CookieImportTemp -Destination $script:CookieImportFinal -Force
                $CookiesBox.Text = $script:CookieImportFinal
                Save-Settings
                Write-Log "YouTube authentication: browser session imported; validating before marking connected."
                Start-YouTubeCookieValidation $script:CookieImportFinal
                return
            } else {
                try { Remove-Item -LiteralPath $script:CookieImportTemp -Force -ErrorAction SilentlyContinue } catch {}
                $allLines | ForEach-Object { Write-Log ([string]$_) }
                $combined = $allLines -join "`n"

                if ($script:CookieImportBrowser -eq "chrome" -and $combined -match "Failed to decrypt with DPAPI") {
                    Write-Log "YouTube authentication: Chrome blocked automatic cookie decryption."
                    Start-FirefoxCookieFallback
                    return
                }

                if ($script:CookieImportBrowser -eq "chrome" -and $combined -match "Could not copy Chrome cookie database") {
                    $ConnectYouTubeButton.IsEnabled = $true
                    Update-YouTubeAuthStatus
                    $FooterState.Text = "YouTube not connected"
                    throw "Chrome still has its cookie database locked. Close Chrome completely and try Connect YouTube again."
                }

                $ConnectYouTubeButton.IsEnabled = $true
                Update-YouTubeAuthStatus
                $FooterState.Text = "YouTube not connected"

                $manual = [System.Windows.MessageBox]::Show(
                    "Automatic browser connection didn't work on this PC.`r`n`r`nIf you already exported a YouTube cookies.txt file, click Yes to select it now. Otherwise click No and use 'Use existing cookies file...' after exporting one.",
                    "Choose YouTube cookies file",
                    [System.Windows.MessageBoxButton]::YesNo,
                    [System.Windows.MessageBoxImage]::Information
                )
                if ($manual -eq [System.Windows.MessageBoxResult]::Yes) {
                    $dlg = New-Object System.Windows.Forms.OpenFileDialog
                    $dlg.Filter = "Cookies text file (*.txt)|*.txt|All files (*.*)|*.*"
                    $dlg.Title = "Select exported YouTube cookies.txt"
                    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                        $CookiesBox.Text = $dlg.FileName
                        Save-Settings
                        Write-Log "YouTube authentication: existing cookies file selected; validating."
                        Start-YouTubeCookieValidation $dlg.FileName
                        return
                    }
                }
            }
        }
        elseif ($mode -eq "resolve") {
            if ($exitCode -ne 0) {
                $allLines | ForEach-Object { Write-Log $_ }
                throw "Could not resolve that YouTube Music link."
            }
            Process-ResolveResult $allLines
        }
        elseif ($mode -eq "preview") {
            if ($stderrLines.Count -gt 0) {
                $stderrLines | ForEach-Object { Write-Log $_ }
            }

            if ($exitCode -ne 0 -and $stdoutLines.Count -eq 0) {
                throw "Could not read that YouTube playlist."
            }

            Process-PreviewResult $stdoutLines
        }
        elseif ($mode -eq "download") {
            $allLines | ForEach-Object { Process-DownloadLine ([string]$_) }

            Import-DownloadMapLog
            Sync-DownloadArchiveFromManifest
            Write-DuplicateTrackReport

            $opus = @(Get-ChildItem -Path $script:AlbumFolder -Filter "*.opus" -File -ErrorAction SilentlyContinue)
            if ($opus.Count -eq 0) {
                throw "No Opus files were created. Open View log to see the yt-dlp error."
            }

            $missing = @(Get-MissingPlaylistIndices)
            if ($missing.Count -gt 0) {
                if (Start-MissingTrackRecovery $missing) {
                    return
                }
            }

            $newFiles = @(Get-NewFilesForTagging)
            Write-UnresolvedTrackReport @()
            $TrackStatusText.Text = "$($opus.Count) of $($script:TrackCount) playlist item(s) downloaded"
            Write-Log "Download complete: $($opus.Count) Opus file(s), 0 unresolved playlist item(s), $($newFiles.Count) new this run."
            Confirm-PostDownloadTagging -Files $newFiles
        }
        elseif ($mode -eq "downloadrecovery") {
            $allLines | ForEach-Object { Process-DownloadLine ([string]$_) }

            Import-DownloadMapLog
            Sync-DownloadArchiveFromManifest
            Write-DuplicateTrackReport

            $afterMissing = @(Get-MissingPlaylistIndices)
            $recovered = [Math]::Max(0, $script:RecoveryInitialCount - $afterMissing.Count)
            $script:RecoveryPassActive = $false

            $opus = @(Get-ChildItem -Path $script:AlbumFolder -Filter "*.opus" -File -ErrorAction SilentlyContinue)
            $newFiles = @(Get-NewFilesForTagging)

            Write-Log "RECOVERY: Second pass recovered $recovered of $($script:RecoveryInitialCount) previously missing track(s)."
            Write-Log "Download complete: $($opus.Count) Opus file(s), $($afterMissing.Count) unresolved playlist item(s), $($newFiles.Count) new this run."
            Write-UnresolvedTrackReport $afterMissing

            if ($afterMissing.Count -gt 0) {
                $TrackStatusText.Text = "$($opus.Count) downloaded • $($afterMissing.Count) unresolved"
                Set-Status "Download finished with unresolved tracks" "$($opus.Count) file(s) on disk; $($afterMissing.Count) unique playlist video(s) still unresolved after the automatic second pass." "Recovery finished"
            } else {
                $TrackStatusText.Text = "$($opus.Count) of $($script:TrackCount) playlist item(s) downloaded"
                Set-Status "Download recovered" "The second pass recovered all $recovered track(s) that were missed on the first pass." "Recovery complete"
            }

            Confirm-PostDownloadTagging -Files $newFiles
        }
    }
    catch {
        $OverallProgress.IsIndeterminate = $false
        if ($youtubeAuthRejected -and $mode -ne "cookieimport" -and $mode -ne "cookievalidate") {
            Set-Status "YouTube login required" "Open Advanced settings and click Connect YouTube, then retry." "Authentication needed"
            [System.Windows.MessageBox]::Show(
                "YouTube wants a signed-in session. Open Advanced settings, click Connect YouTube, and retry.",
                "Connect YouTube"
            ) | Out-Null
        } else {
            Set-Status "Something went wrong" $_.Exception.Message "Error"
        }
        Write-Log "ERROR: $($_.Exception.Message)"
        $LogExpander.IsExpanded = $true
        Set-Busy $false
    }
})
$timer.Start()

function Show-TagLibraryWindow {
    if (-not (Test-Path $PicardBox.Text)) {
        $AdvancedExpander.IsExpanded = $true
        [System.Windows.MessageBox]::Show(
            "Picard.exe was not found. Set its path under Advanced settings first.",
            "OpusBox"
        )
        return
    }

    [xml]$tagXaml = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="OpusBox - Tag Existing Music"
    Width="650"
    Height="620"
    MinWidth="600"
    MinHeight="560"
    WindowStartupLocation="CenterOwner"
    Background="#0B0D12"
    Foreground="#F5F7FB"
    FontFamily="Segoe UI">
    <Window.Resources>
        <SolidColorBrush x:Key="Panel" Color="#12151C"/>
        <SolidColorBrush x:Key="Border" Color="#272C38"/>
        <SolidColorBrush x:Key="Muted" Color="#8F98A8"/>
        <SolidColorBrush x:Key="Accent" Color="#8B5CF6"/>

        <Style TargetType="TextBox">
            <Setter Property="Foreground" Value="#F5F7FB"/>
            <Setter Property="Background" Value="#0F1218"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,8"/>
            <Setter Property="CaretBrush" Value="White"/>
        </Style>

        <Style x:Key="TagPrimaryButton" TargetType="Button">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Background" Value="{StaticResource Accent}"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="16,10"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="9" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="TagSecondaryButton" TargetType="Button">
            <Setter Property="Foreground" Value="#F5F7FB"/>
            <Setter Property="Background" Value="#1A1F29"/>
            <Setter Property="BorderBrush" Value="{StaticResource Border}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,8"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="8"
                                Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="24">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,18">
            <TextBlock Text="Tag Existing Music" FontSize="23" FontWeight="SemiBold"/>
            <TextBlock Text="Fingerprint mixed playlists in small Picard batches instead of treating them as one album."
                       Foreground="{StaticResource Muted}" Margin="0,5,0,0" TextWrapping="Wrap"/>
        </StackPanel>

        <Border Grid.Row="1" Background="{StaticResource Panel}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="12" Padding="15" Margin="0,0,0,14">
            <StackPanel>
                <TextBlock Text="Music folder" FontWeight="SemiBold" Margin="0,0,0,7"/>
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="10"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox x:Name="TagFolderBox" Grid.Column="0" Height="38"/>
                    <Button x:Name="TagBrowseButton" Grid.Column="2" Style="{StaticResource TagSecondaryButton}" Content="Browse"/>
                </Grid>
                <TextBlock x:Name="TagCountText" Text="Choose a folder containing .opus files."
                           Foreground="{StaticResource Muted}" FontSize="12" Margin="0,8,0,0"/>
            </StackPanel>
        </Border>

        <Grid Grid.Row="2" Margin="0,0,0,14">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="14"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <Border Grid.Column="0" Background="{StaticResource Panel}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="12" Padding="15">
                <StackPanel>
                    <TextBlock Text="Batch size" FontWeight="SemiBold"/>
                    <TextBox x:Name="BatchSizeBox" Text="25" Height="38" Margin="0,8,0,0"/>
                    <TextBlock Text="20–30 is a good range for Picard."
                               Foreground="{StaticResource Muted}" FontSize="11" Margin="0,6,0,0"/>
                </StackPanel>
            </Border>

            <Border Grid.Column="2" Background="{StaticResource Panel}" BorderBrush="{StaticResource Border}" BorderThickness="1" CornerRadius="12" Padding="15">
                <StackPanel>
                    <TextBlock Text="Lookup wait / batch" FontWeight="SemiBold"/>
                    <TextBox x:Name="BatchWaitBox" Text="45" Height="38" Margin="0,8,0,0"/>
                    <TextBlock Text="Seconds Picard gets for Scan / AcoustID lookups."
                               Foreground="{StaticResource Muted}" FontSize="11" Margin="0,6,0,0"/>
                </StackPanel>
            </Border>
        </Grid>

        <Border Grid.Row="3" Background="#171B24" CornerRadius="10" Padding="13" Margin="0,0,0,14">
            <TextBlock x:Name="TagSummaryText"
                       Text="Picard will Scan each batch using AcoustID, wait for MusicBrainz / cover art, save matched files twice, then move to the next batch."
                       TextWrapping="Wrap" FontSize="12" Foreground="#C8D0DC"/>
        </Border>

        <TextBox x:Name="TagLogBox" Grid.Row="4"
                 IsReadOnly="True"
                 AcceptsReturn="True"
                 VerticalScrollBarVisibility="Auto"
                 Background="#0D1016"
                 BorderBrush="{StaticResource Border}"
                 Foreground="#CBD2DE"
                 FontFamily="Consolas"
                 FontSize="11"
                 TextWrapping="Wrap"
                 Padding="10"/>

        <Grid Grid.Row="5" Margin="0,16,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="10"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>

            <TextBlock x:Name="TagFooterText"
                       Grid.Column="0"
                       Text="Ready"
                       Foreground="{StaticResource Muted}"
                       VerticalAlignment="Center"/>

            <Button x:Name="TagTestButton"
                    Grid.Column="1"
                    Style="{StaticResource TagSecondaryButton}"
                    Content="Test 1 File"
                    MinWidth="120"/>

            <Button x:Name="TagStartButton"
                    Grid.Column="3"
                    Style="{StaticResource TagPrimaryButton}"
                    Content="Start Batch Tagging"
                    MinWidth="160"/>
        </Grid>
    </Grid>
</Window>
"@

    $tagReader = New-Object System.Xml.XmlNodeReader $tagXaml
    $tagWindow = [Windows.Markup.XamlReader]::Load($tagReader)
    $tagWindow.Owner = $Window

    $tagFolderBox = $tagWindow.FindName("TagFolderBox")
    $tagBrowseButton = $tagWindow.FindName("TagBrowseButton")
    $tagCountText = $tagWindow.FindName("TagCountText")
    $batchSizeBox = $tagWindow.FindName("BatchSizeBox")
    $batchWaitBox = $tagWindow.FindName("BatchWaitBox")
    $tagSummaryText = $tagWindow.FindName("TagSummaryText")
    $tagLogBox = $tagWindow.FindName("TagLogBox")
    $tagFooterText = $tagWindow.FindName("TagFooterText")
    $tagTestButton = $tagWindow.FindName("TagTestButton")
    $tagStartButton = $tagWindow.FindName("TagStartButton")

    $tagQueueState = [pscustomobject]@{
        Process = $null
        LogPath = $null
        LogCache = ""
    }
    $tagQueueTimer = New-Object Windows.Threading.DispatcherTimer
    $tagQueueTimer.Interval = [TimeSpan]::FromSeconds(1)

    $tagQueueTimer.Add_Tick({
        try {
            if ($tagQueueState.LogPath -and (Test-Path $tagQueueState.LogPath)) {
                $nowText = [string](Get-Content -Path $tagQueueState.LogPath -Raw -ErrorAction SilentlyContinue)
                if ($nowText -ne $tagQueueState.LogCache) {
                    $tagQueueState.LogCache = $nowText
                    $tagLogBox.Text = $nowText
                    $tagLogBox.ScrollToEnd()
                }
            }

            $queueComplete = ($tagQueueState.LogCache -match 'Queue complete\.')
            $workerExited = $false
            if ($tagQueueState.Process) {
                try { $workerExited = $tagQueueState.Process.HasExited } catch {}
            }

            if ($queueComplete -or $workerExited) {
                $tagQueueTimer.Stop()

                if ($queueComplete) {
                    $tagFooterText.Text = "Queue complete"
                    $tagSummaryText.Text = "Tagging finished. Matched files were saved; unmatched files were left unchanged on disk."
                } else {
                    $tagFooterText.Text = "Queue stopped with an error"
                    $tagSummaryText.Text = "The tagging worker stopped before completing. Check the queue log above."
                }

                $tagStartButton.Content = "Start Batch Tagging"
                $tagStartButton.IsEnabled = $true
                $tagTestButton.IsEnabled = $true

                if ($tagQueueState.Process -and $workerExited) {
                    try { $tagQueueState.Process.Dispose() } catch {}
                    $tagQueueState.Process = $null
                }
            }
        } catch {}
    })

    $tagWindow.Add_Closed({
        try { $tagQueueTimer.Stop() } catch {}
    })

    if (Test-Path $OutputBox.Text) {
        $tagFolderBox.Text = $OutputBox.Text
    }

    function Update-TagFolderSummary {
        $folder = $tagFolderBox.Text.Trim()
        if (-not (Test-Path $folder)) {
            $tagCountText.Text = "Folder not found."
            return
        }

        $files = @(Get-ChildItem -Path $folder -Filter "*.opus" -File -Recurse -ErrorAction SilentlyContinue)
        $tagCountText.Text = "$($files.Count) Opus file(s) found."
    }

    $tagBrowseButton.Add_Click({
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        if (Test-Path $tagFolderBox.Text) { $dlg.SelectedPath = $tagFolderBox.Text }

        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $tagFolderBox.Text = $dlg.SelectedPath
            Update-TagFolderSummary
        }
    })

    $tagFolderBox.Add_LostFocus({ Update-TagFolderSummary })

    $tagTestButton.Add_Click({
        try {
            $folder = $tagFolderBox.Text.Trim()
            if (-not (Test-Path $folder)) {
                throw "Choose a valid folder first."
            }

            $files = @(Get-ChildItem -Path $folder -Filter "*.opus" -File -Recurse -ErrorAction SilentlyContinue | Sort-Object FullName)
            if ($files.Count -eq 0) {
                throw "No .opus files were found in that folder."
            }

            $testFile = $files[0].FullName

            $tagLogBox.Clear()
            $tagLogBox.AppendText("PICARD 1-FILE POSITIONAL TEST`r`n")
            $tagLogBox.AppendText("==============================`r`n")
            $tagLogBox.AppendText("Test file:`r`n$testFile`r`n`r`n")
            $tagLogBox.AppendText("This build does NOT use Picard's LOAD command.`r`n")
            $tagLogBox.AppendText("The .opus file is passed after an explicit -- separator as a normal positional FILE argument.`r`n`r`n")
            $tagLogBox.AppendText("Expected behavior:`r`n")
            $tagLogBox.AppendText("1. The exact file appears in Unclustered Files.`r`n")
            $tagLogBox.AppendText("2. Picard waits briefly.`r`n")
            $tagLogBox.AppendText("3. Scan / AcoustID runs.`r`n`r`n")

            $tagSummaryText.Text = "Diagnostic mode: one real Windows file path is passed after Picard's -- option separator. LOAD and file:// parsing are completely bypassed."
            $tagFooterText.Text = "Submitting 1-file positional test"
            $tagTestButton.IsEnabled = $false
            $tagTestButton.Content = "Test Submitted"

            Start-PicardFilesAndCommands -Files @($testFile) -Commands @(
                "SHOW",
                "PAUSE 5",
                "SCAN",
                "PAUSE 20",
                "SHOW"
            )

            $tagLogBox.AppendText("Positional file + commands submitted successfully.`r`n")
            $tagLogBox.AppendText("Watch Picard now. The path should remain C:\Users\... exactly as-is.`r`n")
            $tagFooterText.Text = "1-file positional test submitted"
            Write-Log "Picard positional diagnostic submitted for: $testFile"
        }
        catch {
            $tagFooterText.Text = "Diagnostic error"
            $tagLogBox.AppendText("ERROR: $($_.Exception.Message)`r`n")
            [System.Windows.MessageBox]::Show($_.Exception.Message, "OpusBox")
        }
    })
    $tagStartButton.Add_Click({
        try {
            $folder = $tagFolderBox.Text.Trim()
            if (-not (Test-Path $folder)) {
                throw "Choose a valid folder first."
            }

            $batchSize = 0
            if (-not [int]::TryParse($batchSizeBox.Text.Trim(), [ref]$batchSize) -or $batchSize -lt 1 -or $batchSize -gt 100) {
                throw "Batch size must be between 1 and 100."
            }

            $waitSeconds = 0
            if (-not [int]::TryParse($batchWaitBox.Text.Trim(), [ref]$waitSeconds) -or $waitSeconds -lt 5 -or $waitSeconds -gt 300) {
                throw "Lookup wait must be between 5 and 300 seconds."
            }

            $oldWorkers = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
                Where-Object { $_.CommandLine -and $_.CommandLine -match 'picard-queue-[0-9]{8}-[0-9]{6}\.ps1' })

            if ($oldWorkers.Count -gt 0) {
                $workerPids = ($oldWorkers | ForEach-Object { [string]$_.ProcessId }) -join ", "
                $answer = [System.Windows.MessageBox]::Show(
                    "Another OpusBox Picard queue is still running (PID: $workerPids).`r`n`r`nStop the old queue and start this one?",
                    "OpusBox",
                    [System.Windows.MessageBoxButton]::YesNo,
                    [System.Windows.MessageBoxImage]::Warning
                )

                if ($answer -ne [System.Windows.MessageBoxResult]::Yes) {
                    throw "Existing Picard queue left running. New queue was not started."
                }

                foreach ($oldWorker in $oldWorkers) {
                    Stop-Process -Id $oldWorker.ProcessId -Force -ErrorAction SilentlyContinue
                }
                Start-Sleep -Milliseconds 500
            }

            $files = @(Get-ChildItem -Path $folder -Filter "*.opus" -File -Recurse -ErrorAction SilentlyContinue | Sort-Object FullName)
            if ($files.Count -eq 0) {
                throw "No .opus files were found in that folder."
            }

            $batchCount = [int][Math]::Ceiling($files.Count / [double]$batchSize)
            $commandDir = Join-Path $env:APPDATA "OpusBox"
            if (-not (Test-Path $commandDir)) {
                New-Item -ItemType Directory -Path $commandDir -Force | Out-Null
            }

            $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $workerPath = Join-Path $commandDir ("picard-queue-" + $stamp + ".ps1")
            $listPath = Join-Path $commandDir ("picard-queue-" + $stamp + "-files.json")
            $queueLog = Join-Path $commandDir ("picard-queue-" + $stamp + ".log")

            $filePathArray = @($files | ForEach-Object { [string]$_.FullName })
            ConvertTo-Json -InputObject $filePathArray -Compress |
                Set-Content -Path $listPath -Encoding UTF8

            $workerScript = @'
param(
    [Parameter(Mandatory=$true)][string]$Picard,
    [Parameter(Mandatory=$true)][string]$ListPath,
    [Parameter(Mandatory=$true)][string]$LogPath,
    [Parameter(Mandatory=$true)][int]$WaitSeconds,
    [Parameter(Mandatory=$true)][int]$BatchSize
)

$ErrorActionPreference = "Stop"

function Log([string]$Text) {
    $line = "[$(Get-Date -Format HH:mm:ss)] $Text"
    Add-Content -Path $LogPath -Value $line -Encoding UTF8
}

function Quote-Arg([string]$Argument) {
    if ($null -eq $Argument) { return '""' }
    if ($Argument -notmatch '[\s"]') { return $Argument }

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('"')
    $slashes = 0

    foreach ($ch in $Argument.ToCharArray()) {
        if ($ch -eq '\') {
            $slashes++
            continue
        }

        if ($ch -eq '"') {
            if ($slashes -gt 0) {
                [void]$sb.Append(('\' * ($slashes * 2)))
                $slashes = 0
            }
            [void]$sb.Append('\\"')
            continue
        }

        if ($slashes -gt 0) {
            [void]$sb.Append(('\' * $slashes))
            $slashes = 0
        }

        [void]$sb.Append($ch)
    }

    if ($slashes -gt 0) {
        [void]$sb.Append(('\' * ($slashes * 2)))
    }

    [void]$sb.Append('"')
    return $sb.ToString()
}

function Run-Picard([string[]]$Files, [string[]]$Commands) {
    $argv = New-Object System.Collections.Generic.List[string]

    foreach ($cmd in $Commands) {
        $argv.Add("-e")
        $argv.Add([string]$cmd)
    }

    if ($Files.Count -gt 0) {
        $argv.Add("--")
        foreach ($f in $Files) {
            $pathText = [string]$f
            if ([string]::IsNullOrWhiteSpace($pathText)) {
                throw "Picard queue contained an empty file path."
            }
            if (-not (Test-Path -LiteralPath $pathText)) {
                throw "Queued audio file does not exist: $pathText"
            }
            $argv.Add([System.IO.Path]::GetFullPath($pathText))
        }
    }

    $line = ($argv | ForEach-Object { Quote-Arg ([string]$_) }) -join " "

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Picard
    $psi.Arguments = $line
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.WorkingDirectory = Split-Path $Picard -Parent

    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi

    if (-not $p.Start()) {
        throw "Could not start Picard."
    }

    $senderPid = $p.Id
    if ($p.WaitForExit(5000)) {
        Log "Picard batch handoff completed (sender PID $senderPid exited)."
    } else {
        Log "Picard batch process PID $senderPid remains active; continuing after command submission."
    }
    try { $p.Dispose() } catch {}
}

try {
    Log "Worker process started."
    Log "Picard path: $Picard"
    Log "File list: $ListPath"

    if (-not (Test-Path $Picard)) {
        throw "Picard.exe not found at: $Picard"
    }

    if (-not (Test-Path $ListPath)) {
        throw "File list not found at: $ListPath"
    }

    Log "Picard will be started by the first real batch submission; no separate primary GUI is pre-launched."

    $json = Get-Content -Path $ListPath -Raw
    $parsed = ConvertFrom-Json -InputObject $json

    $Files = @($parsed | ForEach-Object { [string]$_ })

    if ($Files.Count -eq 0) {
        throw "The queue file list was empty."
    }

    Log "Parsed file count: $($Files.Count)"
    Log "First file: $($Files[0])"

    $BatchCount = [int][Math]::Ceiling($Files.Count / [double]$BatchSize)
    Log "Queue started: $($Files.Count) files, $BatchCount batches."

    for ($offset = 0; $offset -lt $Files.Count; $offset += $BatchSize) {
        $batchNumber = [int]($offset / $BatchSize) + 1

        $batch = @($Files | Select-Object -Skip $offset -First $BatchSize)

        if ($batch.Count -eq 0) {
            throw "Batch $batchNumber was unexpectedly empty."
        }

        Log "Batch ${batchNumber} / ${BatchCount}: loading $($batch.Count) files."
        Log "Batch first path: $($batch[0])"

        Run-Picard -Files $batch -Commands @(
            "SHOW",
            "PAUSE 2",
            "SCAN",
            "PAUSE $WaitSeconds",
            "SAVE_MATCHED",
            "PAUSE 8",
            "SAVE_MATCHED",
            "PAUSE 2",
            "REMOVE_SAVED",
            "REMOVE_EMPTY",
            "REMOVE_UNCLUSTERED"
        )

        Log "Batch ${batchNumber} / ${BatchCount}: scan/save command queue submitted."
        Log "Batch ${batchNumber} / ${BatchCount}: waiting for Picard to finish matching, artwork and saves."
        Start-Sleep -Seconds ($WaitSeconds + 16)
        Log "Batch ${batchNumber} / ${BatchCount} complete."
    }

    Log "Queue complete."
}
catch {
    try {
        Log ("FATAL: " + $_.Exception.Message)
        Log ("STACK: " + $_.ScriptStackTrace)
    } catch {}
    exit 1
}
'@

            $workerScript | Set-Content -Path $workerPath -Encoding UTF8

            $tokens = $null
            $parseErrors = $null
            [void][System.Management.Automation.Language.Parser]::ParseFile(
                $workerPath,
                [ref]$tokens,
                [ref]$parseErrors
            )

            if ($parseErrors -and $parseErrors.Count -gt 0) {
                $msg = ($parseErrors | ForEach-Object {
                    "Line $($_.Extent.StartLineNumber): $($_.Message)"
                }) -join "`r`n"

                throw "Generated Picard worker has a PowerShell parse error:`r`n`r`n$msg`r`n`r`nWorker file:`r`n$workerPath"
            }

            $estimatedMinutes = [Math]::Ceiling(($batchCount * ($waitSeconds + 16)) / 60.0)

            $tagLogBox.Clear()
            $tagLogBox.AppendText("SEQUENTIAL PICARD QUEUE`r`n")
            $tagLogBox.AppendText("=======================`r`n")
            $tagLogBox.AppendText("Files: $($files.Count)`r`n")
            $tagLogBox.AppendText("Batch size: $batchSize`r`n")
            $tagLogBox.AppendText("Batches: $batchCount`r`n")
            $tagLogBox.AppendText("Lookup wait: $waitSeconds sec / batch`r`n")
            $tagLogBox.AppendText("Estimated minimum time: ~${estimatedMinutes} min`r`n`r`n")
            $tagLogBox.AppendText("Worker script:`r`n$workerPath`r`n`r`n")
            $tagLogBox.AppendText("File list:`r`n$listPath`r`n`r`n")
            $tagLogBox.AppendText("Queue log:`r`n$queueLog`r`n`r`n")
            $tagLogBox.AppendText("Song filenames are stored in JSON instead of being embedded in PowerShell code.`r`n")
            $tagLogBox.AppendText("The worker owns one Picard session and submits ONE complete batch command queue at a time.`r`n")

            $args = @(
                "-NoProfile",
                "-ExecutionPolicy", "Bypass",
                "-WindowStyle", "Hidden",
                "-File", $workerPath,
                "-Picard", $PicardBox.Text,
                "-ListPath", $listPath,
                "-LogPath", $queueLog,
                "-WaitSeconds", [string]$waitSeconds,
                "-BatchSize", [string]$batchSize
            )

            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "powershell.exe"
            $psi.Arguments = Convert-ToProcessArgumentString $args
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true

            $proc = New-Object System.Diagnostics.Process
            $proc.StartInfo = $psi

            if (-not $proc.Start()) {
                throw "Could not start the Picard queue worker."
            }

            Start-Sleep -Milliseconds 1200

            if ($proc.HasExited) {
                $details = ""
                if (Test-Path $queueLog) {
                    $details = [string](Get-Content $queueLog -Raw -ErrorAction SilentlyContinue)
                }
                if ([string]::IsNullOrWhiteSpace($details)) {
                    $details = "Worker exited immediately with code $($proc.ExitCode)."
                }
                throw "Picard queue worker stopped immediately:`r`n`r`n$details"
            }

            $tagQueueState.Process = $proc
            $tagQueueState.LogPath = $queueLog
            $tagQueueState.LogCache = ""
            $tagQueueTimer.Start()

            $tagFooterText.Text = "Queue running • $batchCount batch(es)"
            $tagSummaryText.Text = "One background worker is feeding a single Picard instance: load → Scan → wait → save twice → clean → next batch."
            $tagStartButton.IsEnabled = $false
            $tagStartButton.Content = "Queue Running"
            $tagTestButton.IsEnabled = $false

            Write-Log "External sequential Picard worker started: $workerPath"
            Write-Log "Picard queue log: $queueLog"
        }
        catch {
            $tagFooterText.Text = "Error"
            $tagLogBox.AppendText("ERROR: $($_.Exception.Message)`r`n")
            [System.Windows.MessageBox]::Show($_.Exception.Message, "OpusBox")
        }
    })
    Update-TagFolderSummary
    [void]$tagWindow.ShowDialog()
}

$TagLibraryUrlButton.Add_Click({ Show-TagLibraryWindow })
$PreviewButton.Add_Click({ Start-Preview })
$DownloadButton.Add_Click({ Start-Download })

$UrlBox.Add_TextChanged({
    if (-not $UrlBox.IsFocused) { return }
    $script:AlbumTitle = ""
    $script:ResolvedUrl = ""
    $script:Tracks = @()
})

$ConnectYouTubeButton.Add_Click({
    $existing = $CookiesBox.Text.Trim()
    if (-not [string]::IsNullOrWhiteSpace($existing) -and (Test-Path -LiteralPath $existing)) {
        Start-YouTubeCookieValidation $existing
    } else {
        Start-YouTubeConnection
    }
})

$BrowseCookiesButton.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "Cookies text file (*.txt)|*.txt|All files (*.*)|*.*"
    $dlg.Title = "Select YouTube cookies.txt"
    if (-not [string]::IsNullOrWhiteSpace($CookiesBox.Text) -and (Test-Path -LiteralPath $CookiesBox.Text)) {
        $dlg.FileName = $CookiesBox.Text
    }
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $CookiesBox.Text = $dlg.FileName
        Save-Settings
        Write-Log "YouTube authentication: existing cookies file selected; validating."
        Start-YouTubeCookieValidation $dlg.FileName
    }
})

$BrowseOutputButton.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    if (Test-Path $OutputBox.Text) { $dlg.SelectedPath = $OutputBox.Text }
    if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $OutputBox.Text = $dlg.SelectedPath
        $SaveLocationText.Text = $OutputBox.Text
        Save-Settings
    }
})

$OutputBox.Add_LostFocus({ $SaveLocationText.Text = $OutputBox.Text; Save-Settings })
$YtDlpBox.Add_LostFocus({ Save-Settings; Update-ToolHealth })
$PicardBox.Add_LostFocus({ Save-Settings; Update-ToolHealth })
$OpenFolderCheck.Add_Click({ Save-Settings })

$Window.Add_Closing({
    Save-Settings
    if ($script:CurrentProcess) {
        try {
            if (-not $script:CurrentProcess.HasExited) { $script:CurrentProcess.Kill() }
            $script:CurrentProcess.Dispose()
        } catch {}
    }
})

Load-Settings
[void]$Window.ShowDialog()
