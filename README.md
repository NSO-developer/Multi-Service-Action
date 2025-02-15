# Multi service action

## Description
There are various examples of action points associated with list items, which 
allow procedures to be invoked on specific items. A common example is a list 
of services. NSO provides multiple built-in actions that can be invoked by 
users, such as re-deploy, check-sync, and others. In some cases, it is 
desirable to invoke a specific action on a subset or even all items in a list. 
Making individual calls for each item might be overly complex for the 
northbound client to manage, highlighting the need for an action that can 
handle this scenario efficiently.

The [multi-service-action](packages/multi-service-action) package addresses this need in a generic manner, 
enabling its use across any type of list without the need to write callback 
code. It can be easily attached to a list by importing it into the YANG model 
and loading the package. Although it is currently tailored for services, it 
can be adapted to other lists and actions by modifying the YANG model. The 
underlying Python logic supports any action without requiring further 
modification.

Moreover, the logic can be extended as needed, for example, by adding output 
formatting or other functionalities. The existing logic serves as a foundation 
for invoking multiple actions through a single API call, without performing 
additional tasks. Each separate API call is invoked asynchronously by the base 
action, allowing NSO to execute them concurrently.

## Installing the package
To utilize the package, please add the following to your package-meta-data.xml 
file:
```
  <required-package>
    <name>multi-service-action</name>
  </required-package>
```
This will register the dependency on the `multi-service-action` package, 
ensuring that NSO does not permit your package to be loaded without the 
`multi-service-action` package being present.

Additionally, the following line must be added to the Makefile of your package:
```
YANGPATH += ../../multi-service-action/src/yang
```
This inclusion allows the YANG compiler to locate the YANG module for the 
`multi-service-action` package, where the action definitions are specified.

The package utilizes maagic-copy, which must be loaded alongside it. The 
maagic-copy package can be downloaded from the following link: 
https://gitlab.com/nso-developer/maagic-copy

## Incorporating the package to your service list

Upon completion of the installation, the grouping that contains the action 
point can be integrated into your model. Please note that groupings can only 
be loaded into lists and containers. Consequently, the targeted list must not 
reside at the root of the CDB schema.

### Using the grouping
The following is a YANG snippet illustrating a service point defined for each 
instance of the test-service list.
```
  container test-services {
    list test-service {

      key name;
      leaf name {
        tailf:info "Unique service id";
        tailf:cli-allow-range;
        type string;
      }

      uses ncs:service-data;
      ncs:servicepoint test-service-servicepoint;

      leaf device {
        type leafref {
          path "/ncs:devices/ncs:device/ncs:name";
        }
        mandatory true;
      }
    }
  }
```

The test-list is located within a container named test-services. Therefore, 
the multi-service-actions grouping should be placed inside that container.
```
  container test-services {
    uses multi-service-action:multi-service-actions;

    list test-service {
      key name;
      leaf name {
        tailf:info "Unique service id";
        tailf:cli-allow-range;
        type string;
      }

      uses ncs:service-data;
      ncs:servicepoint test-service-servicepoint;

      leaf device {
        type leafref {
          path "/ncs:devices/ncs:device/ncs:name";
        }
        mandatory true;
      }

    }
  }
```

This configuration enables the invocation of the multi-service-action from the 
test-services grouping, allowing it to target all services within the 
test-list.


### Enabling explicit service targeting

Utilizing the grouping as-is will result in any action invocation targeting 
all instances within the container. To target specific services, you must add 
a parameter for this purpose. By augmenting a leaf-list into each desired 
action, you can enable the capability to target specific services. The 
leaf-list will be automatically recognized by the action logic, ensuring that 
the action is invoked only for the specified leaf-list items.

```
  container test-services {
    uses multi-service-action:multi-service-actions {
      augment "re-deploy/input" {
        leaf-list services {
          type leafref {
            path "/test-service:test-services/test-service:test-service/test-service:name";
          }
        }
      }
      augment "check-sync/input" {
        leaf-list services {
          type leafref {
            path "/test-service:test-services/test-service:test-service/test-service:name";
          }
        }
      }
    }

    list test-service {
      key name;
      leaf name {
        tailf:info "Unique service id";
        tailf:cli-allow-range;
        type string;
      }

      uses ncs:service-data;
      ncs:servicepoint test-service-servicepoint;

      leaf device {
        type leafref {
          path "/ncs:devices/ncs:device/ncs:name";
        }
        mandatory true;
      }

    }
  }
```

## Using the package
You can now utilize the action for all services:
```
admin@ncs> request test-services re-deploy
service {
    name /test-service:test-services/test-service{test0}
}
service {
    name /test-service:test-services/test-service{test1}
}
service {
    name /test-service:test-services/test-service{test2}
}
```

Or by targeting specific services:
```
admin@ncs> request test-services re-deploy services [ test1 test2 ]
service {
    name /test-service:test-services/test-service{test1}
}
service {
    name /test-service:test-services/test-service{test2}
}
```
