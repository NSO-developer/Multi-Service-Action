# -*- mode: python; python-indent: 4 -*-
import ncs
from ncs.application import Service
import time

class ServiceCallbacks(Service):
    @Service.create
    def cb_create(self, tctx, root, service, proplist):
        self.log.info('Service create(service=', service._path, ')')
        time.sleep(0.5)
        root.ncs__devices.device[service.device].config.r__sys.interfaces.interface.create('eth1').description = service.name


class Main(ncs.application.Application):
    def setup(self):
        self.log.info('Main RUNNING')
        self.register_service('test-service-servicepoint', ServiceCallbacks)

    def teardown(self):
        self.log.info('Main FINISHED')
