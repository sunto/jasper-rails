# -*- encoding: utf-8 -*
module JasperRails
  
  class DefaultRenderer < JasperReportsRenderer
    
    register :pdf, :mime_type => 'application/pdf' do |jasper_print, options|
      _JasperExportManager = Rjb::import 'net.sf.jasperreports.engine.JasperExportManager'
      _JasperExportManager._invoke('exportReportToPdf', 'Lnet.sf.jasperreports.engine.JasperPrint;', jasper_print)
    end

    register :csv, :mime_type => 'text/csv' do |jasper_print, options|
      export jasper_print, 'net.sf.jasperreports.engine.export.JRCsvExporter'
    end
    
    register :odt, :mime_type => 'application/vnd.oasis.opendocument.text, application/x-vnd.oasis.opendocument.text' do |jasper_print|
      export jasper_print, 'net.sf.jasperreports.engine.export.oasis.JROdtExporter'
    end
  
    # It looks like xhtml is already registered, but there's no Mime::XHTML. So we need this until we find another solution. 
    Mime::Type.register('text/html', :xhtml)
    register :xhtml, :mime_type => 'text/html' do |jasper_print, options|
      export jasper_print, 'net.sf.jasperreports.engine.export.JRXhtmlExporter'
    end
    
    register :swf, :mime_type => 'application/swf' do |jasper_print, options|
      _JasperExportManager = Rjb::import 'net.sf.jasperreports.engine.JasperExportManager'
      _JavaString          = Rjb::import 'java.lang.String'
      
      # Save it
      temp_dir = Dir::mktmpdir
      pdf_file = temp_dir + '/report.pdf'
      swf_file = temp_dir + '/report.swf'
      _JasperExportManager._invoke('exportReportToPdfFile', 'Lnet.sf.jasperreports.engine.JasperPrint;Ljava.lang.String;', jasper_print, _JavaString.new(pdf_file))
      
      # Convert to swf
      run_command "pdf2swf -t -T9 -f -s storeallcharacters #{pdf_file} -o #{swf_file}"
      
      # Get the stream
      swf_stream = open(swf_file) { |f| f.read }
      
      # Clean the mess
      FileUtils.rm_rf temp_dir
      
      swf_stream
    end

    private

    def run_command(command)
      output = `#{command} 2>&1`
      raise RuntimeError.new("Command failed: #{command}\n#{output}") unless $?.success?
    end

  end
end
