import QtQuick

QtObject {
    property string currentLanguage: "zh"

    readonly property var en: ({
        "app.title": "LumiTeX",
        "topbar.newProject": "New Project",
        "topbar.openProject": "Open Project",
        "topbar.closeProject": "Close Project",
        "topbar.save": "Save",
        "topbar.noProject": "No Project",
        "topbar.noFile": "No File",
        "topbar.currentFile": "Current File",
        "topbar.compile": "Compile",
        "topbar.preview": "Preview",
        "topbar.clean": "Clean",
        "topbar.dark": "Dark",
        "topbar.light": "Light",
        "topbar.settings": "Settings",
        "sidebar.openFiles": "OPEN FILES",
        "sidebar.project": "PROJECT",
        "sidebar.file": "FILE",
        "sidebar.noOpenFiles": "No files opened",
        "sidebar.noProjectFiles": "No project files",
        "editor.find": "Find",
        "editor.findPlaceholder": "command, label, word",
        "editor.next": "Next",
        "editor.saved": "Saved",
        "editor.modified": "Modified",
        "editor.loadingFile": "Loading file...",
        "editor.noMatch": "No results",
        "editor.tooManyMatches": "Too many matches, showing first 500.",
        "editor.line": "Line",
        "editor.section": "Section",
        "editor.subsection": "Subsection",
        "editor.equation": "Equation",
        "editor.figure": "Figure",
        "editor.table": "Table",
        "editor.cite": "Cite",
        "editor.ref": "Ref",
        "editor.itemize": "Itemize",
        "editor.syntax": "Syntax",
        "editor.syntaxNone": "no LaTeX markers detected",
        "editor.comments": "comments",
        "editor.mathMarkers": "math markers",
        "pdf.preview": "PDF Preview",
        "pdf.fitWidth": "Fit Width",
        "pdf.placeholder": "Placeholder",
        "pdf.rendered": "Rendered",
        "pdf.fit": "Fit",
        "pdf.compileToRender": "Compile to render the real PDF preview",
        "pdf.welcomeTitle": "Welcome to LumiTeX",
        "pdf.welcomeSubtitle": "Open or create a LaTeX project, then compile to preview the PDF here.",
        "pdf.welcomeStepTitle": "Get started",
        "pdf.welcomeStepOne": "Create a new project or open an existing LaTeX folder.",
        "pdf.welcomeCompileTitle": "Preview",
        "pdf.welcomeStepTwo": "Compile your document and the generated PDF will appear here.",
        "welcome.editorSubtitle": "A modern local LaTeX writing studio",
        "welcome.getStarted": "Get started:",
        "image.preview": "Image Preview",
        "image.fitWindow": "Fit Window",
        "image.zoomIn": "Zoom In",
        "image.zoomOut": "Zoom Out",
        "image.loadFailed": "Failed to load image.",
        "problems.title": "Problems",
        "problems.structured": "STRUCTURED MESSAGES",
        "problems.rawLog": "RAW LOG",
        "problems.errorReport": "ERROR REPORT",
        "problems.copyReport": "Copy Report",
        "problems.rawLogView": "Raw Log",
        "problems.reportView": "Error Report",
        "problems.reportCopied": "Report copied.",
        "problems.noMessages": "No compiler messages yet.",
        "problems.rawPlaceholder": "Raw LaTeX log will appear here after compile.",
        "problems.item": "item",
        "problems.items": "items",
        "problem.warning": "warning",
        "problem.error": "error",
        "problem.info": "info",
        "settings.title": "Settings",
        "settings.compiler": "Compiler",
        "settings.compilerEngine": "Compiler Engine",
        "settings.editor": "Editor",
        "settings.editorFont": "Editor Font",
        "settings.fontSize": "Font Size",
        "settings.lineWrap": "Line Wrap",
        "settings.project": "Project",
        "settings.defaultProjectDirectory": "Default Project Directory",
        "settings.theme": "Theme",
        "settings.language": "Language",
        "settings.english": "English",
        "settings.chinese": "中文",
        "settings.dark": "Dark",
        "settings.light": "Light",
        "settings.system": "System",
        "settings.browse": "Browse",
        "settings.save": "Save",
        "settings.cancel": "Cancel",
        "newProject.title": "New Project",
        "newProject.heading": "Create LaTeX Project",
        "newProject.projectName": "Project name",
        "newProject.template": "Template",
        "newProject.location": "Choose save location",
        "newProject.browse": "Browse",
        "newProject.create": "Create",
        "newProject.cancel": "Cancel",
        "template.article": "Basic Article",
        "template.ieee_twocolumn": "IEEE-style Two-column"
    })

    readonly property var zh: ({
        "app.title": "LumiTeX",
        "topbar.newProject": "新建项目",
        "topbar.openProject": "打开项目",
        "topbar.closeProject": "关闭项目",
        "topbar.save": "保存",
        "topbar.noProject": "未打开项目",
        "topbar.noFile": "无文件",
        "topbar.currentFile": "当前文件",
        "topbar.compile": "编译",
        "topbar.preview": "预览",
        "topbar.clean": "清理",
        "topbar.dark": "深色",
        "topbar.light": "浅色",
        "topbar.settings": "设置",
        "sidebar.openFiles": "已打开文件",
        "sidebar.project": "项目",
        "sidebar.file": "文件",
        "sidebar.noOpenFiles": "暂无打开文件",
        "sidebar.noProjectFiles": "暂无项目文件",
        "editor.find": "查找",
        "editor.findPlaceholder": "命令、标签、词语",
        "editor.next": "下一个",
        "editor.saved": "已保存",
        "editor.modified": "已修改",
        "editor.loadingFile": "正在加载文件……",
        "editor.noMatch": "无结果",
        "editor.tooManyMatches": "匹配结果过多，仅显示前 500 个。",
        "editor.line": "第 %1 行",
        "editor.section": "一级标题",
        "editor.subsection": "二级标题",
        "editor.equation": "公式",
        "editor.figure": "图片",
        "editor.table": "表格",
        "editor.cite": "引用",
        "editor.ref": "交叉引用",
        "editor.itemize": "列表",
        "editor.syntax": "语法",
        "editor.syntaxNone": "未检测到 LaTeX 标记",
        "editor.comments": "注释",
        "editor.mathMarkers": "数学标记",
        "pdf.preview": "PDF 预览",
        "pdf.fitWidth": "适应宽度",
        "pdf.placeholder": "占位预览",
        "pdf.rendered": "已渲染",
        "pdf.fit": "适应",
        "pdf.compileToRender": "编译后显示真实 PDF 预览",
        "pdf.welcomeTitle": "欢迎使用 LumiTeX",
        "pdf.welcomeSubtitle": "新建或打开一个 LaTeX 项目后，编译结果将在这里显示。",
        "pdf.welcomeStepTitle": "开始写作",
        "pdf.welcomeStepOne": "新建项目，或打开已有 LaTeX 文件夹。",
        "pdf.welcomeCompileTitle": "预览",
        "pdf.welcomeStepTwo": "编译文档后，生成的 PDF 会显示在这里。",
        "welcome.editorSubtitle": "现代本地 LaTeX 论文写作工作台",
        "welcome.getStarted": "请选择一个操作开始：",
        "image.preview": "图片预览",
        "image.fitWindow": "适应窗口",
        "image.zoomIn": "放大",
        "image.zoomOut": "缩小",
        "image.loadFailed": "图片加载失败。",
        "problems.title": "问题",
        "problems.structured": "结构化信息",
        "problems.rawLog": "原始日志",
        "problems.errorReport": "错误报告",
        "problems.copyReport": "复制报告",
        "problems.rawLogView": "原始日志",
        "problems.reportView": "错误报告",
        "problems.reportCopied": "报告已复制。",
        "problems.noMessages": "暂无编译信息。",
        "problems.rawPlaceholder": "编译后将在这里显示原始 LaTeX 日志。",
        "problems.item": "项",
        "problems.items": "项",
        "problem.warning": "警告",
        "problem.error": "错误",
        "problem.info": "信息",
        "settings.title": "设置",
        "settings.compiler": "编译器",
        "settings.compilerEngine": "编译引擎",
        "settings.editor": "编辑器",
        "settings.editorFont": "编辑器字体",
        "settings.fontSize": "字体大小",
        "settings.lineWrap": "自动换行",
        "settings.project": "项目",
        "settings.defaultProjectDirectory": "默认项目目录",
        "settings.theme": "主题",
        "settings.language": "语言",
        "settings.english": "English",
        "settings.chinese": "中文",
        "settings.dark": "深色",
        "settings.light": "浅色",
        "settings.system": "跟随系统",
        "settings.browse": "浏览",
        "settings.save": "保存",
        "settings.cancel": "取消",
        "newProject.title": "新建项目",
        "newProject.heading": "创建 LaTeX 项目",
        "newProject.projectName": "项目名称",
        "newProject.template": "模板",
        "newProject.location": "选择保存位置",
        "newProject.browse": "浏览",
        "newProject.create": "创建",
        "newProject.cancel": "取消",
        "template.article": "基础文章",
        "template.ieee_twocolumn": "IEEE 风格双栏模板"
    })

    function t(key) {
        var table = currentLanguage === "zh" ? zh : en
        return table[key] || en[key] || key
    }

    function lineText(lineNumber) {
        if (currentLanguage === "zh") {
            return t("editor.line").replace("%1", lineNumber)
        }
        return t("editor.line") + " " + lineNumber
    }

    function itemCount(count) {
        if (currentLanguage === "zh") {
            return count + " " + t("problems.items")
        }
        return count + " " + (count === 1 ? t("problems.item") : t("problems.items"))
    }

    function problemType(typeName) {
        return t("problem." + typeName)
    }

    function templateName(templateId, fallbackName) {
        var key = "template." + templateId
        var value = t(key)
        return value === key ? fallbackName : value
    }

    function status(message) {
        if (currentLanguage !== "zh") {
            return message
        }
        if (message === "Compile succeeded. PDF generated.") return "编译成功，PDF 已生成。"
        if (message === "Compile failed.") return "编译失败。"
        if (message === "No auxiliary files found.") return "未找到可清理的临时文件。"
        if (message === "Compiling...") return "正在编译……"
        if (message === "File saved.") return "文件已保存。"
        if (message === "File loaded.") return "文件已加载。"
        if (message === "Loading file...") return "正在加载文件……"
        if (message === "Project opened.") return "项目已打开。"
        if (message === "Project loaded successfully") return "项目加载成功"
        if (message === "No project opened.") return "未打开项目。"
        if (message === "Please open or create a project first.") return "请先打开或新建项目。"
        if (message === "Please open a project first.") return "请先打开项目。"
        if (message === "No file to save.") return "当前没有可保存的文件。"
        if (message === "This file is large and may load slowly.") return "文件较大，加载可能较慢。"
        if (message === "Settings saved.") return "设置已保存。"
        if (message === "Template loaded.") return "模板已加载。"
        if (message === "Project created.") return "项目已创建。"
        if (message === "Project closed.") return "项目已关闭。"
        if (message === "Cleaning auxiliary files...") return "正在清理临时文件……"
        if (message === "Image imported.") return "图片已导入。"
        if (message === "Failed to import image.") return "图片导入失败。"
        if (message === "Unsupported image format.") return "不支持的图片格式。"
        if (message === "The graphicx package is required to include images.") return "插入图片需要 graphicx 宏包。"
        if (message === "No TeX file found to compile.") return "未找到可编译的 TeX 文件。"
        if (message === "This file type is not supported for text editing yet.") return "当前文件类型暂不支持文本编辑。"
        if (message === "This file type is not supported for preview yet.") return "当前文件类型暂不支持预览。"
        if (message === "Image preview mode does not need saving.") return "图片预览模式无需保存。"

        var cleaned = message.match(/^Cleaned (\d+) auxiliary files\.$/)
        if (cleaned) {
            return "已清理 " + cleaned[1] + " 个临时文件。"
        }
        var compilingCurrent = message.match(/^Compiling current file: (.+)$/)
        if (compilingCurrent) {
            return "正在编译当前文件：" + compilingCurrent[1]
        }
        var compilingWith = message.match(/^Compiling with (.+)\.\.\.$/)
        if (compilingWith) {
            return "正在使用 " + compilingWith[1] + " 编译……"
        }
        var compileSucceeded = message.match(/^Compile succeeded\. PDF generated: (.+)$/)
        if (compileSucceeded) {
            return "编译成功，PDF 已生成：" + compileSucceeded[1]
        }
        var compileFailed = message.match(/^Compile failed: (.+)$/)
        if (compileFailed) {
            return "编译失败：" + compileFailed[1]
        }
        return message
    }
}
