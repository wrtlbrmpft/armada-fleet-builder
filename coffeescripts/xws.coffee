exportObj = exports ? this

exportObj.fromXWSFaction =
    'rebel': 'Rebel Alliance'
    'rebels': 'Rebel Alliance'
    'empire': 'Galactic Empire'
    'imperial': 'Galactic Empire'
    'scum': 'Scum and Villainy'

exportObj.toXWSFaction =
    'Rebel Alliance': 'rebel'
    'Galactic Empire': 'imperial'
    'Scum and Villainy': 'scum'

exportObj.toXWSUpgrade =
    'Astromech': 'amd'
    'Elite': 'ept'
    'Modification': 'mod'
    'Salvaged Astromech': 'samd'

exportObj.fromXWSUpgrade =
    'amd': 'Astromech'
    'astromechdroid': 'Astromech'
    'ept': 'Elite'
    'elitepilottalent': 'Elite'
    'mod': 'Modification'
    'samd': 'Salvaged Astromech'

SPEC_URL = 'https://github.com/elistevens/xws-spec'

class exportObj.XWSManager
    constructor: (args) ->
        @container = $ args.container

        @setupUI()
        @setupHandlers()

    setupUI: ->
        @container.addClass 'hidden-print'
        @container.html $.trim """
            <div class="row-fluid">
                <div class="span9">
                    <button class="btn btn-primary from-xws">Import from XWS (beta)</button>
                    <button class="btn btn-primary to-xws">Export to XWS (beta)</button>
                </div>
            </div>
        """

        @xws_export_modal = $ document.createElement 'DIV'
        @xws_export_modal.addClass 'modal hide fade xws-modal hidden-print'
        @container.append @xws_export_modal
        @xws_export_modal.append $.trim """
            <div class="modal-header">
                <button type="button" class="close hidden-print" data-dismiss="modal" aria-hidden="true">&times;</button>
                <h3>XWS Export (Beta!)</h3>
            </div>
            <div class="modal-body">
                <ul class="nav nav-pills">
                    <li><a id="xws-text-tab" href="#xws-text" data-toggle="tab">Text</a></li>
                    <li><a id="xws-qrcode-tab" href="#xws-qrcode" data-toggle="tab">QR Code</a></li>
                </ul>
                <div class="tab-content">
                    <div class="tab-pane" id="xws-text">
                        Copy and paste this into an XWS-compliant application to transfer your list.
                        <i>(This is in beta, and the <a href="#{SPEC_URL}">spec</a> is still being defined, so it may not work!)</i>
                        <div class="container-fluid">
                            <textarea class="xws-content"></textarea>
                        </div>
                    </div>
                    <div class="tab-pane" id="xws-qrcode">
                        Below is a QR Code of XWS.  <i>This is still very experimental!</i>
                        <div id="xws-qrcode-container"></div>
                    </div>
                </div>
            </div>
            <div class="modal-footer hidden-print">
                <button class="btn" data-dismiss="modal" aria-hidden="true">Close</button>
            </div>
        """

        @xws_import_modal = $ document.createElement 'DIV'
        @xws_import_modal.addClass 'modal hide fade xws-modal hidden-print'
        @container.append @xws_import_modal
        @xws_import_modal.append $.trim """
            <div class="modal-header">
                <button type="button" class="close hidden-print" data-dismiss="modal" aria-hidden="true">&times;</button>
                <h3>XWS Import (Beta!)</h3>
            </div>
            <div class="modal-body">
                Paste XWS here to load a list exported from another application.
                <i>(This is in beta, and the <a href="#{SPEC_URL}">spec</a> is still being defined, so it may not work!)</i>
                <div class="container-fluid">
                    <textarea class="xws-content" placeholder="Paste XWS here..."></textarea>
                </div>
            </div>
            <div class="modal-footer hidden-print">
                <span class="xws-import-status"></span>&nbsp;
                <button class="btn btn-primary import-xws">Import It!</button>
                <button class="btn" data-dismiss="modal" aria-hidden="true">Close</button>
            </div>
        """

    setupHandlers: ->
        @from_xws_button = @container.find('button.from-xws')
        @from_xws_button.click (e) =>
            e.preventDefault()
            @xws_import_modal.modal 'show'

        @to_xws_button = @container.find('button.to-xws')
        @to_xws_button.click (e) =>
            e.preventDefault()
            $(window).trigger 'xwing:pingActiveBuilder', (builder) =>
                textarea = $ @xws_export_modal.find('.xws-content')
                textarea.attr 'readonly'
                textarea.val JSON.stringify(builder.toXWS())
                $('#xws-qrcode-container').text ''
                $('#xws-qrcode-container').qrcode
                    render: 'canvas'
                    text: JSON.stringify(builder.toMinimalXWS())
                    ec: 'L'
                    size: 256
                @xws_export_modal.modal 'show'
                $('#xws-text-tab').tab 'show'
                textarea.select()
                textarea.focus()

        $('#xws-qrcode-container').click (e) ->
            window.open $('#xws-qrcode-container canvas')[0].toDataURL()

        @load_xws_button = $ @xws_import_modal.find('button.import-xws')
        @load_xws_button.click (e) =>
            e.preventDefault()
            import_status = $ @xws_import_modal.find('.xws-import-status')
            import_status.text 'Loading...'
            do (import_status) =>
                try
                    xws = JSON.parse @xws_import_modal.find('.xws-content').val()
                catch e
                    import_status.text 'Invalid JSON'
                    return

                do (xws) =>
                    $(window).trigger 'xwing:activateBuilder', [exportObj.fromXWSFaction[xws.faction], (builder) =>
                        if builder.current_squad.dirty and builder.backend?
                            @xws_import_modal.modal 'hide'
                            builder.backend.warnUnsaved builder, =>
                                builder.loadFromXWS xws, (res) =>
                                    unless res.success
                                        @xws_import_modal.modal 'show'
                                        import_status.text res.error
                        else
                            builder.loadFromXWS xws, (res) =>
                                if res.success
                                    @xws_import_modal.modal 'hide'
                                else
                                    import_status.text res.error
                    ]
