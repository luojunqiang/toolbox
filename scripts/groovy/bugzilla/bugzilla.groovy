//@Grab(group='org.codehaus.groovy.modules.http-builder', module='http-builder', version='0.5.0-RC2' )
import groovyx.net.http.*
import static groovyx.net.http.ContentType.*
import static groovyx.net.http.Method.*
import net.sf.jxls.transformer.XLSTransformer;

class BugZilla {
    def http

    BugZilla(rootUrl) {
        http = new HTTPBuilder( rootUrl)
    }
    
    def setProxy(host, port) {
        http.setProxy(host, port, null)
    }
    
    def login(username, password) {
        http.request(POST, TEXT) { req ->
            uri.path = '/index.cgi'
            send URLENC, [Bugzilla_login:username, Bugzilla_password:password, GoAheadAndLogIn:'Log in']
            response.success = { resp, reader ->
                //System.out << reader
            }
        }
    }
    
    def query() {
        def bugIdList = []
        http.request(GET, HTML) { req ->
            uri.path = '/buglist.cgi'
            uri.query = [query_format:'specific', order:'relevance+desc', bug_status:'__closed__', product:'TestProduct', content:'']
            response.success = { resp, reader ->
                reader.depthFirst().findAll{ it.name() == 'FORM' && it.@action == 'show_bug.cgi' }[0].
                        INPUT.findAll{it.@name == 'id'}.@value.each{bugIdList += it}
                //System.out << reader
            }
        }
        println bugIdList;
        
        //print http.parser[XML].metaClass.methods*.name
        def bugs
        http.request(POST, TEXT) { req ->
            uri.path = '/show_bug.cgi'
            send URLENC, [ctype:'xml', excludefield:'attachmentdata', id:bugIdList ]
            response.success = { resp, reader ->
                def parser = new XmlSlurper()
                parser.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false)
                parser.setFeature("http://xml.org/sax/features/namespaces", false) 
                bugs = parser.parse(reader) 
                //System.out << reader
            }
        }
        return bugs.bug
    }
} // end of class BugZilla

class BugTransformer {
    
    def genUser(i) {
        return "${i.@name} <${i}>".toString()
    }
    
    def genContent(bug) {
        def content = '', history = '', full_history = ''
        
        bug.long_desc.each {
            history = full_history
            full_history += "#### ${it.bug_when.text().substring(5,16)} [${it.who.@name}]:\n${it.thetext}\n"
            content = it.thetext
        }
        return [content, history, full_history]
    }
    
    def formatDate(t) {
        return t?.toString().substring(0, 19)
    }
    
    def transformBug(bug) {
        def r = [:]
        r.id = bug.bug_id
        r.title = bug.short_desc
        r.created_on = formatDate(bug.creation_ts)
        r.last_changed_on = formatDate(bug.delta_ts)
        r.classification = bug.classification
        r.product = bug.product
        r.component = bug.component
        r.version = bug.version
        r.platform = bug.rep_pltform
        r.os = bug.op_sys
        r.priority = bug.priority
        r.severity = r.bug_severity
        r.target_milestone = bug.target_milestone
        r.everconfirmed = bug.everconfirmed
        r.status = bug.bug_status //bug.resolution
        r.reporter = genUser(bug.reporter) //"${bug.reporter.@name} <${bug.reporter}>"
        r.assigned_to = genUser(bug.assigned_to)
        bugContent = genContent(bug)
        r.content = bugContent[0]; r.history = bugContent[1]; r.full_history = bugContent[2]
        r.fixed_on = formatDate(bug.bug_status in ['CLOSED'] && bug.resolution in ['FIXE'] ? bug.delta_ts : '')
        r.closed_on = formatDate(bug.bug_status in ['CLOSED', 'VERIFIED'] ? bug.delta_ts : '')
        
        //UNCONFIRMED	NEW	ASSIGNED	REOPENED	
        //RESOLVED	VERIFIED	CLOSED
        //'FIXED', 'INVALID', 'WONTFIX', 'DUPLICATE', 'WORKSFORME', 'INCOMPLETE'
        
        r.cmp_bug_task = bug.cf_cmp_task
        r.cmp_bug_class = bug.cf_cmp_bug_class
        r.cmp_customer = bug.cf_cmp_customer
        r.cmp_sample = bug.cf_cmp_sample
        
        return r
    }

    def transformBugs(bugs) {
        def bugList = []
        bugs.each{ println it.bug_id; bugList += transformBug(it) }
        return bugList
    }
}

def bugzilla = new BugZilla('http://bugzilla.sample.com/')
bugzilla.setProxy('cmproxy.gmcc.net',8081)
bugzilla.login('test@sample.com', 'mypwd')
def bugs = bugzilla.query()
println '---------'
//println bugs
println '---------'


def trans = new XLSTransformer()
def templateFileName = 'bug_template.xlsx'
def destFileName = 'bugs.xlsx'

def beans = new HashMap()
def list = new BugTransformer().transformBugs(bugs)
//println list
beans.put('bug', list)
trans.transformXLS(templateFileName, beans, destFileName);

/*
dbf.setFeature("http://xml.org/sax/features/namespaces", false);
dbf.setFeature("http://xml.org/sax/features/validation", false);
dbf.setFeature("http://apache.org/xml/features/nonvalidating/load-dtd-grammar", false);
dbf.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
*/

