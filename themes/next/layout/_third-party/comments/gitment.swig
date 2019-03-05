{% if theme.gitment.enable %}
     {% set owner = 'crazyfzw' %}
     {% set repo = 'crazyfzw.github.io' %}
     {% set cid ='68162ffa9d22306220bb' %}
     {% set cs = '7d9d23ec452f702c9dfa4ed7ea085cbdde99af9f' %}
     <link rel="stylesheet" href="https://imsun.github.io/gitment/style/default.css">
     <script src="https://www.wenjunjiang.win/js/gitment.js"></script>
     {% if not theme.gitment.lazy %}
         <script type="text/javascript">
             var gitment = new Gitment({
                 id: '{{page.date}}', 
                 owner: '{{owner}}',
                 repo: '{{repo}}',
                 oauth: {
                     client_id: '{{cid}}',
                     client_secret: '{{cs}}'
                 }});
             gitment.render('gitment-container');
         </script>
     {% else %}
         <script type="text/javascript">
             function ShowGitment(){
                 document.getElementById("gitment-display-button").style.display = "none";
                 document.getElementById("gitment-container").style.display = "block";
                 var gitment = new Gitment({
                     id: '{{page.date}}', 
                     owner: '{{owner}}',
                     repo: '{{repo}}',
                     oauth: {
                         client_id: '{{cid}}',
                         client_secret: '{{cs}}',
                     }});
                 gitment.render('gitment-container');
             }
         </script>
     {% endif %}
 {% endif %}