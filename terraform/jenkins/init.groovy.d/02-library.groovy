import jenkins.model.Jenkins
import jenkins.plugins.git.GitSCMSource
import org.jenkinsci.plugins.workflow.libs.*

println("Configuring Global Shared Library...")

def globalLibraries = GlobalLibraries.get()

def scm = new GitSCMSource(
    "shared-library",
    "https://github.com/AmanSharma05/Jenkins_SharedLib.git",
    "",
    "*",
    "",
    false
)

def library = new LibraryConfiguration(
    "Shared",
    new SCMSourceRetriever(scm)
)

library.setDefaultVersion("main")
library.setImplicit(false)
library.setAllowVersionOverride(true)

globalLibraries.setLibraries([library])

Jenkins.get().save()

println("Global Shared Library configured successfully.")