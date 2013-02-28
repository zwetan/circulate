package library.circulate.utils
{
    import flash.system.Security;

    public function isAIR():Boolean
    {
        return Security.sandboxType == Security.APPLICATION;
    }
}