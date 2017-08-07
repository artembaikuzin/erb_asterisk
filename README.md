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

#### Render template
```
<%= render 'template_file_name_without_ext', variable_name: variable_value %>
```

#### Define inclusion to external configuration file
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

Also, you can define priority for inclusion:
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

#### Apply line to a tag

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

#### Escape special symbols in extension name
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
