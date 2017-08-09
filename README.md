# erb_asterisk

This gem is add ability to declare asterisk configuration with ERB files.

## Installation

    $ gem install erb_asterisk

## Usage

### Create ERB configuration files and templates
```
├── asterisk
...
│   ├── entities
│   │   ├── office
│   │   │   ├── pjsip_endpoints.conf
│   │   │   └── pjsip_endpoints.conf.erb
│   │   ├── taxi
│   │   │   ├── pjsip_endpoints.conf
│   │   │   ├── pjsip_endpoints.conf.erb
│   │   │   ├── queues.conf
│   │   │   └── queues.conf.erb
...
│   ├── pjsip_endpoints.conf
│   ├── pjsip_endpoints.conf.includes
...
│   ├── queues.conf
│   ├── queues.conf.includes
...
│   ├── templates
│   │   ├── pjsip_operators.erb
│   │   └── queues.erb
```

### Templates

Templates can be defined in `asterisk/templates`, user home directory `~/.erb_asterisk/templastes`, or via command line argument `--templates`.

pjsip_operators.erb:
```
[<%= op %>](operator)
auth=<%= op %>
aors=<%= op %>
set_var=GROUP()=operator<%= op %>
[<%= op %>](operator-auth)
username=<%= op %>
[<%= op %>](aor-single-reg)
<% end %>
```

queues.erb:
```
[operators-<%= name %>]
strategy = rrmemory
joinempty = yes
musicclass = queue
<% members.times.each do |i| %>
<% op = offset + i %>
<% group = 100 + i %>
member => Local/<%= "#{group}#{op}" %>@queue-dial-control,0,,SIP/<%= op %>
<% end %>
ringinuse = no
announce-frequency = 30
announce-holdtime = no
retry = 0
```

### ERB extensions

#### render: render template
```
<%= render 'template_file_name_without_ext', variable_name: variable_value %>
```

#### include_to: define inclusion to external configuration file
```
<%= include_to 'pjsip_endpoints.conf.includes' %>
```
This will create (overwrite) file pjsip_endpoints.conf.includes with `#include` command of current processed erb file. For example:

pjsip_endpoints.conf.includes:
```
#include "entities/office/pjsip_endpoints.conf"
#include "entities/taxi/pjsip_endpoints.conf"
...
```

You can include this file to your actual pjsip_endpoints.conf.

Also, you can define `priority` argument for inclusion:
```
<%= include_to 'pjsip_endpoints.conf.includes' %>
<%= include_to 'pjsip_endpoints.conf.includes', priority: 999 %>
```
This will render to:
```
; priority: 999
#include "entities/taxi/pjsip_endpoints.conf"
#include "entities/office/pjsip_endpoints.conf"
```

#### apply_line_to: apply line to a tag

office/extensions.conf.erb:
```
[office-inbound]
<% apply_line_to :global_inbound_context, 'include => office-inbound' %>
```

extensions.conf.erb:
```
[inbound]
<%= yield_here :global_inbound_context %>
```
This will render to:

extensions.conf:
```
[inbound]
; Yield for :global_inbound_context
include => office-inbound
```

#### content_for: apply block to a tag
office/extensions.conf.erb:
```
<% content_for :global_outbound_context do %>
<% exten = 'super_extension-' -%>
exten => _<%= escape_exten exten %>X.,1,NoOp
same => n,Goto(another-extension,${EXTEN:<%= exten.size %>},1)
<% end %>
```

extensions.conf.erb:
```
[outbound]
<%= yield_here :global_outbound_context %>
```

extensions.conf:
```
[outbound]
; Yield for :outbound
exten => _super_e[x]te[n]sio[n]-X.,1,NoOp
same => n,Goto(another-extension,${EXTEN:16},1)
```

`apply_line_to` and `content_for` can has `priority` argument, just like `include_to` method:
```
<% content_for :global_outbound_context, priority: 999 do %>
...
<% apply_line_to :outbound_glob, 'include => outbound', priority: -10 %>
```

#### escape_exten: escape special symbols in extension name
```
exten => _<%= escape_exten 'LongExtension1234!' %>-X.,1,NoOp
```

Renders to:
```
exten => _Lo[n]gE[x]te[n]sio[n]1234[!]-X.,1,NoOp
```

#### Global variables

Project available global variables can be defined inside file `erb_asterisk_project.rb`, e.g.:
```
OPERATORS_SIZE = 31

LAN = '192.168.1.0/255.255.255.0'
EXTERNAL_HOST = 'no-ip.some.host.eg'
```

### Command line arguments

```
usage: exe/erb_asterisk [options]
    -t, --templates  set templates path (e.g.: ~/.erb_asterisk)
    -v, --version    print the version
    -h, --help       print this help
```

### Run erb_asterisk

    $ cd /etc/asterisk
    $ erb_asterisk
