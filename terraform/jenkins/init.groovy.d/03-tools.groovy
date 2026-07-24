import hudson.plugins.git.GitTool
import hudson.plugins.git.GitTool.DescriptorImpl
import hudson.tools.InstallSourceProperty
import jenkins.model.Jenkins
import java.util.Collections
import hudson.plugins.sonar.SonarRunnerInstallation
import hudson.plugins.sonar.SonarRunnerInstaller
import org.jenkinsci.plugins.DependencyCheck.tools.DependencyCheckInstallation
import org.jenkinsci.plugins.DependencyCheck.tools.DependencyCheckInstaller

println("Configuring Jenkins Tools")

def jenkins = Jenkins.get()

def gitDescriptor = jenkins.getDescriptorByType(DescriptorImpl.class)

gitDescriptor.setInstallations(
    new GitTool(
        "Default",
        "/usr/bin/git",
        Collections.emptyList()
    )
)
gitDescriptor.save()
println("Git tool configured.")

def sonarDescriptor = jenkins.getDescriptorByType(
    SonarRunnerInstallation.DescriptorImpl.class
)

def sonarInstallation = new SonarRunnerInstallation(
    "Sonar",
    "/opt/sonar-scanner",
    Collections.<InstallSourceProperty>emptyList()
)

sonarDescriptor.setInstallations(sonarInstallation)
sonarDescriptor.save()

println("SonarScanner configured.") 

def dependencyDescriptor = jenkins.getDescriptorByType(
    DependencyCheckInstallation.DescriptorImpl.class
)

def dependencyInstallation = new DependencyCheckInstallation(
    "OWASP",
    "/opt/dependency-check-12.1.8",
    Collections.<InstallSourceProperty>emptyList()
)
dependencyDescriptor.setInstallations(dependencyInstallation)
dependencyDescriptor.save()
println("OWASP Dependency Check configured.")
jenkins.save()
println("Jenkins tools configured successfully.")