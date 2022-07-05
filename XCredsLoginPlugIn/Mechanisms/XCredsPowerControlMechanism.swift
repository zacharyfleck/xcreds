//
//  PowerControl.swift
//  NoMADLoginAD
//
//  Created by Josh Wisenbaker on 2/9/18.
//  Copyright © 2018 NoMAD. All rights reserved.
//

import IOKit
import IOKit.pwr_mgt

enum SpecialUsers: String {
    case sleep
    case restart
    case shutdown
    case standardLoginWindow
}

class XCredsPowerControlMechanism: XCredsBaseMechanism {

    @objc override func run() {
        TCSLog("PowerControl mech starting")

        guard let userName = xcredsUser else {
            if AuthorizationDBManager.shared.rightExists(right: "loginwindow:login"){
                TCSLog("setting standard login back to XCreds login")
                let _ = AuthorizationDBManager.shared.replace(right:"loginwindow:login", withNewRight: "XCredsLoginPlugin:LoginWindow")
            }
            else {
                TCSLog("No username was set somehow, pass the login to the next mech.")

            }

            let _ = allowLogin()
            return
        }

        switch userName {
        case SpecialUsers.sleep.rawValue:
            TCSLog("Sleeping system.")
            let port = IOPMFindPowerManagement(mach_port_t(MACH_PORT_NULL))
            IOPMSleepSystem(port)
            IOServiceClose(port)
        case SpecialUsers.shutdown.rawValue:
            TCSLog("Shutting system down system")
            let _ = cliTask("/sbin/shutdown -h now")
        case SpecialUsers.restart.rawValue:
            TCSLog("Restarting system")
            let _ = cliTask("/sbin/shutdown -r now")

        case SpecialUsers.standardLoginWindow.rawValue:
            TCSLog("Setting back to login window")
            let res = AuthorizationDBManager.shared.replace(right:"XCredsLoginPlugin:LoginWindow", withNewRight: "loginwindow:login")

            if res == false {
                TCSLog("could not restore loginwindow right")
                denyLogin()
                return
            }
            let _ = cliTask("/usr/bin/killall loginwindow")

        default:
            TCSLog("No special users named. pass login to the next mech.")

            let _ = allowLogin()
        }
    }
}