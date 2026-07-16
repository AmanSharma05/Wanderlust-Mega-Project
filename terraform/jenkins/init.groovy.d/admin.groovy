#!groovy

import jenkins.model.*
import hudson.security.*

def instance = Jenkins.get()

println("Configuring Jenkins Admin User...")

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "Admin@123")

instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)

instance.setAuthorizationStrategy(strategy)

instance.save()

println("Jenkins Admin User configured.")